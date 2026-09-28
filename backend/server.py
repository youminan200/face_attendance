import os
from contextlib import asynccontextmanager
from typing import Optional
from fastapi import FastAPI, HTTPException, status, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel
from config.database import init_db
from config.universities import UNIVERSITY_REGISTRY
from adapters.factory import UniversityAdapterFactory
import services.student_service as student_service
import services.professor_service as professor_service
import services.course_service as course_service
import services.university_portal_service as uni_service


@asynccontextmanager
async def lifespan(app: FastAPI):
    # 서버 기동 시 DB 테이블 자동 생성
    init_db()
    yield

app = FastAPI(
    title="Face Attendance & University SSO Gateway Server",
    description="얼굴 인식 기반 스마트 출결 관리 및 전국 대학교 학사·SSO 연동 게이트웨이",
    version="2.0.0",
    lifespan=lifespan,
)

# 모바일 앱 및 웹 접근을 위한 CORS 전면 허용
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class SignUpRequest(BaseModel):
    school: str = ""
    major: str = ""
    name: str
    id: str
    role: str = "학생"
    password: str
    faceTemplate: str

class LoginRequest(BaseModel):
    id: str
    password: str
    role: str = "학생"

class UniversityAuthRequest(BaseModel):
    username: str = ""
    password: str = ""
    code: str = ""
    cadet_id: str = ""

class UniversitySyncRequest(BaseModel):
    student_id: str
    student_name: str = ""
    student_major: str = ""
    school_name: str = ""

class AttendanceRecordRequest(BaseModel):
    student_id: str
    course_id: str
    course_title: str
    attendance_date: str
    attendance_time: str
    status: str
    similarity_score: float

class CourseCreateRequest(BaseModel):
    course_name: str
    professor_id: str
    professor_name: str
    professor_dept: str = ""
    professor_office: str = ""
    day: str = "월"
    time: str = "13:00~15:00"
    room: str = "공학관 101호"
    notice: str = ""

class CourseUpdateRequest(BaseModel):
    course_name: Optional[str] = None
    day: Optional[str] = None
    time: Optional[str] = None
    room: Optional[str] = None
    professor_dept: Optional[str] = None
    professor_office: Optional[str] = None

class CourseNoticeRequest(BaseModel):
    notice: str

class CourseEnrollRequest(BaseModel):
    student_id: str

@app.get("/api/info")
def home():
    return {
        "status": "online",
        "service": "Face Attendance API & University SSO Gateway",
        "registered_universities_count": len(UNIVERSITY_REGISTRY),
        "version": "2.0.0"
    }

@app.get("/health")
def health_check():
    """클라우드 PaaS Liveness 및 헬스체크용 엔드포인트"""
    return {"status": "healthy"}

# ==============================================================================
# 1. 전국 대학교 마스터 및 검색 API
# ==============================================================================
@app.get("/api/universities")
def list_universities(
    q: Optional[str] = Query(None, description="학교명 또는 영문/지역 검색"),
    limit: int = Query(100, description="반환 개수"),
):
    """진학사 기반 대한민국 전국 468개 대학교 마스터 정보 실시간 검색"""
    results = uni_service.search_jinhak_universities(query=q or "", limit=limit)
    return {
        "status": "success",
        "total": len(results),
        "universities": results,
    }

@app.get("/api/university/campus-map")
def get_campus_map(school_name: str = Query(..., description="대학교명")):
    """선택한 대학교의 실제 캠퍼스 지도 레이아웃 및 건물/강의실 데이터 반환"""
    data = uni_service.get_university_campus_map_data(school_name)
    return {
        "status": "success",
        "campus_map": data
    }

@app.get("/api/universities/{univ_code}")
def get_university_detail(univ_code: str):
    """특정 대학 연동 메타데이터 조회"""
    univ = UNIVERSITY_REGISTRY.get(univ_code.lower())
    if not univ:
        raise HTTPException(status_code=404, detail="지원되지 않는 대학교 코드입니다.")
    return {"status": "success", "university": univ.model_dump()}

# ==============================================================================
# 2. 대학별 학사/SSO 어댑터 연동 엔드포인트
# ==============================================================================
@app.post("/api/universities/{univ_code}/auth")
async def authenticate_with_university(univ_code: str, data: UniversityAuthRequest):
    """선택한 대학교의 포털/SSO/사관학교 LDAP 서버로 인증 위임 프록시"""
    univ = UNIVERSITY_REGISTRY.get(univ_code.lower())
    if not univ:
        raise HTTPException(status_code=404, detail=f"대학교({univ_code}) 정보를 찾을 수 없습니다.")

    adapter = UniversityAdapterFactory.get_adapter(univ)
    auth_result = await adapter.authenticate(data.model_dump())

    if auth_result.success:
        return {
            "status": "success",
            "auth": auth_result.to_dict(),
            "university": univ.model_dump()
        }
    else:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=auth_result.message or "대학교 인증에 실패했습니다."
        )

@app.get("/api/universities/{univ_code}/courses")
async def get_university_courses(univ_code: str, student_id: str = Query(..., description="학번/군번")):
    """대학교 학사 서버에서 해당 학생의 당학기 수강 과목 목록 자동 동기화"""
    univ = UNIVERSITY_REGISTRY.get(univ_code.lower())
    if not univ:
        raise HTTPException(status_code=404, detail="등록되지 않은 대학교입니다.")

    adapter = UniversityAdapterFactory.get_adapter(univ)
    courses = await adapter.fetch_enrolled_courses(student_id)
    return {
        "status": "success",
        "university": univ.name,
        "student_id": student_id,
        "courses": courses
    }

@app.post("/api/universities/{univ_code}/attendance")
async def sync_attendance_to_university(univ_code: str, record: AttendanceRecordRequest):
    """모바일 앱에서 완료된 얼굴 인증 출결 결과를 대학교 학사 서버로 동기화 전송"""
    univ = UNIVERSITY_REGISTRY.get(univ_code.lower())
    if not univ:
        raise HTTPException(status_code=404, detail="등록되지 않은 대학교입니다.")

    adapter = UniversityAdapterFactory.get_adapter(univ)
    success = await adapter.push_attendance_record(record.model_dump())
    if success:
        return {"status": "success", "message": f"{univ.name} 학사 서버로 출석 정보가 동기화되었습니다."}
    else:
        raise HTTPException(status_code=500, detail="대학교 학사 출결 서버 동기화 실패")

# ==============================================================================
# 3. 로컬 회원가입 및 로그인 기본 API
# ==============================================================================
@app.post("/api/signup", status_code=status.HTTP_200_OK)
def signup(data: SignUpRequest):
    try:
        if data.role == "학생":
            success = student_service.register_student(
                data.id, data.password, data.name, data.school, data.major, data.faceTemplate
            )
        else:
            success = professor_service.register_professor(
                data.id, data.password, data.name, data.school, data.major, data.faceTemplate
            )

        if success:
            return {"status": "success", "message": "회원가입이 완료되었습니다."}

        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="이미 존재하는 학번/교번이거나 정보가 올바르지 않습니다."
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"회원가입 처리 중 오류가 발생했습니다: {str(e)}"
        )

@app.post("/api/login", status_code=status.HTTP_200_OK)
def login(data: LoginRequest):
    try:
        if data.role == "학생":
            profile = student_service.get_student_profile(data.id, data.password)
        else:
            profile = professor_service.get_professor_profile(data.id, data.password)

        if profile:
            return {"status": "success", "profile": profile}

        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="ID 또는 비밀번호가 틀렸습니다."
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"로그인 처리 중 서버 오류가 발생했습니다: {str(e)}"
        )

# ==============================================================================
# 4. 교수님 수업 개설/관리, 공지 업데이트, 학생 수강 신청 및 수강생 명단 API
# ==============================================================================
@app.post("/api/courses", status_code=status.HTTP_201_CREATED)
def create_new_course(data: CourseCreateRequest):
    """교수님 새 수업 개설"""
    created = course_service.create_course(
        course_name=data.course_name,
        professor_id=data.professor_id,
        professor_name=data.professor_name,
        professor_dept=data.professor_dept,
        professor_office=data.professor_office,
        day=data.day,
        time=data.time,
        room=data.room,
        notice=data.notice,
    )
    if not created:
        raise HTTPException(status_code=400, detail="강의 개설에 실패했습니다.")
    return {"status": "success", "course": created}

@app.get("/api/courses")
def list_courses(q: Optional[str] = Query(None), professor_id: Optional[str] = Query(None)):
    """강의 목록 검색 및 조회"""
    courses = course_service.get_courses(query=q, professor_id=professor_id)
    return {"status": "success", "total": len(courses), "courses": courses}

@app.get("/api/professors/{prof_id}/courses")
def get_professor_courses(prof_id: str):
    """특정 교수님이 개설한 강의 목록 조회"""
    courses = course_service.get_courses(professor_id=prof_id)
    return {"status": "success", "courses": courses}

@app.put("/api/courses/{course_id}/notice")
def update_course_notice_endpoint(course_id: int, data: CourseNoticeRequest):
    """교수님의 수업 공지사항 업데이트"""
    ok = course_service.update_course_notice(course_id, data.notice)
    if not ok:
        raise HTTPException(status_code=404, detail="강의를 찾을 수 없거나 공지 업데이트에 실패했습니다.")
    return {"status": "success", "message": "수업 공지사항이 성공적으로 등록되었습니다."}

@app.put("/api/courses/{course_id}")
def update_course_endpoint(course_id: int, data: CourseUpdateRequest):
    """수업 정보 수정"""
    ok = course_service.update_course(course_id, data.model_dump(exclude_unset=True))
    if not ok:
        raise HTTPException(status_code=404, detail="강의 정보를 수정할 수 없습니다.")
    return {"status": "success", "message": "강의 정보가 수정되었습니다."}

@app.delete("/api/courses/{course_id}")
def delete_course_endpoint(course_id: int):
    """강의 삭제"""
    ok = course_service.delete_course(course_id)
    if not ok:
        raise HTTPException(status_code=404, detail="강의 삭제에 실패했습니다.")
    return {"status": "success", "message": "강의가 삭제되었습니다."}

@app.post("/api/courses/{course_id}/enroll")
def enroll_course(course_id: int, data: CourseEnrollRequest):
    """학생의 수업 수강 등록 (교수님 수업 추가)"""
    ok = course_service.enroll_student(course_id, data.student_id)
    if not ok:
        raise HTTPException(status_code=400, detail="수강 등록에 실패했습니다.")
    return {"status": "success", "message": "수업이 내 시간표에 추가되었습니다."}

@app.delete("/api/courses/{course_id}/enroll")
def unenroll_course(course_id: int, student_id: str = Query(...)):
    """학생의 수업 수강 취소"""
    ok = course_service.unenroll_student(course_id, student_id)
    return {"status": "success", "message": "수업 수강이 취소되었습니다."}

@app.get("/api/courses/{course_id}/students")
def get_course_students(course_id: int):
    """특정 수업에 등록된 수강생 명단 및 출결 현황 조회 (교수님용)"""
    students = course_service.get_enrolled_students(course_id)
    return {"status": "success", "total": len(students), "students": students}

@app.get("/api/students/{student_id}/courses")
def get_student_enrolled_courses(student_id: str):
    """학생이 수강 중인 강의 목록 조회 (교수님 프로필 및 최신 공지 포함)"""
    courses = course_service.get_student_courses(student_id)
    return {"status": "success", "total": len(courses), "courses": courses}

# ==========================================
# 실시간 대학교 수강정보 시스템 (학사정보시스템) 연동 라우터
# ==========================================
@app.get("/api/university/courses")
def get_university_catalog(q: str = None):
    """대학교 수강정보 시스템 개설 강좌 전체 목록 조회"""
    uni_service.seed_university_courses_if_needed()
    courses = course_service.get_courses(query=q)
    return {"status": "success", "total": len(courses), "courses": courses}

@app.post("/api/university/sync-student-courses")
def sync_student_courses(data: UniversitySyncRequest):
    """대학교 종합정보시스템 수강정보 실시간 연동 (학생 시간표 일괄 동기화)"""
    courses = uni_service.sync_student_university_courses(
        student_id=data.student_id,
        student_name=data.student_name,
        student_major=data.student_major,
        school_name=data.school_name,
    )
    return {
        "status": "success",
        "message": f"대학교 수강정보 시스템에서 {len(courses)}개 수업을 실시간으로 불러왔습니다.",
        "synced_count": len(courses),
        "courses": courses
    }


# ==========================================
# Flutter 웹앱 (SPA) 통합 서빙 라우터
# ==========================================
import os
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse

web_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "face_attendance", "build", "web"))
if os.path.exists(web_dir):
    @app.get("/")
    async def serve_root():
        return FileResponse(os.path.join(web_dir, "index.html"))

    @app.get("/{full_path:path}")
    async def serve_spa_asset(full_path: str):
        # API 엔드포인트 및 문서 경로는 제외
        if full_path.startswith("api/") or full_path == "api" or full_path.startswith("docs") or full_path.startswith("openapi.json"):
            raise HTTPException(status_code=404, detail="Not Found")
        
        file_path = os.path.join(web_dir, full_path)
        if os.path.isfile(file_path):
            return FileResponse(file_path)
        return FileResponse(os.path.join(web_dir, "index.html"))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("server:app", host="0.0.0.0", port=8080, reload=True)