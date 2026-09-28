import pytest
from fastapi.testclient import TestClient
from server import app
from config.database import init_db

client = TestClient(app)

def test_course_lifecycle_and_enrollment():
    init_db()

    # 1. 교수 회원가입
    prof_id = "prof_kim_01"
    client.post("/api/signup", json={
        "id": prof_id,
        "password": "password123",
        "name": "김영호",
        "school": "한국대학교",
        "major": "컴퓨터공학과",
        "role": "교수",
        "faceTemplate": "test_face_template_prof"
    })

    # 2. 학생 회원가입
    student_id = "20260101"
    client.post("/api/signup", json={
        "id": student_id,
        "password": "password123",
        "name": "홍길동",
        "school": "한국대학교",
        "major": "컴퓨터공학과",
        "role": "학생",
        "faceTemplate": "test_face_template_student"
    })

    # 3. 교수님이 새 수업 개설
    create_res = client.post("/api/courses", json={
        "course_name": "스마트 모바일 앱 개발",
        "professor_id": prof_id,
        "professor_name": "김영호",
        "professor_dept": "컴퓨터공학과",
        "professor_office": "공학관 501호 (010-1234-5678)",
        "day": "화",
        "time": "14:00~16:00",
        "room": "IT융합관 302호",
        "notice": "다음 주 화요일 개강 첫 오리엔테이션이 진행됩니다."
    })
    assert create_res.status_code == 201
    course_data = create_res.json()["course"]
    course_id = int(course_data["id"])
    assert course_data["course_name"] == "스마트 모바일 앱 개발"
    assert course_data["professor_name"] == "김영호"
    assert course_data["notice"] == "다음 주 화요일 개강 첫 오리엔테이션이 진행됩니다."

    # 4. 교수님 수업 목록 조회
    prof_courses_res = client.get(f"/api/professors/{prof_id}/courses")
    assert prof_courses_res.status_code == 200
    p_courses = prof_courses_res.json()["courses"]
    assert any(c["id"] == str(course_id) for c in p_courses)

    # 5. 교수님이 수업 공지사항 업데이트
    update_notice_res = client.put(f"/api/courses/{course_id}/notice", json={
        "notice": "[중요] 1주차 준비물: 개인 노트북 및 Flutter SDK 사전 설치 요망"
    })
    assert update_notice_res.status_code == 200

    # 6. 학생이 교수님의 수업을 검색 및 수강 신청 (교수님 수업 추가)
    enroll_res = client.post(f"/api/courses/{course_id}/enroll", json={
        "student_id": student_id
    })
    assert enroll_res.status_code == 200

    # 7. 교수님 화면: 해당 수업의 수강생 명단 확인 (홍길동 학생이 등록되어 있는지 확인)
    students_res = client.get(f"/api/courses/{course_id}/students")
    assert students_res.status_code == 200
    students = students_res.json()["students"]
    assert len(students) >= 1
    enrolled_student = next(s for s in students if s["student_id"] == student_id)
    assert enrolled_student["name"] == "홍길동"
    assert enrolled_student["major"] == "컴퓨터공학과"
    assert enrolled_student["has_face_registered"] is True

    # 8. 학생 화면: 내 수강 수업 목록 확인 (교수님 상세 정보와 업데이트된 공지사항 확인)
    my_courses_res = client.get(f"/api/students/{student_id}/courses")
    assert my_courses_res.status_code == 200
    my_courses = my_courses_res.json()["courses"]
    my_c = next(c for c in my_courses if c["id"] == str(course_id))
    assert my_c["professor_name"] == "김영호"
    assert my_c["professor_dept"] == "컴퓨터공학과"
    assert my_c["professor_office"] == "공학관 501호 (010-1234-5678)"
    assert my_c["notice"] == "[중요] 1주차 준비물: 개인 노트북 및 Flutter SDK 사전 설치 요망"

    print(">>> 모든 교수-학생 수업 관리 및 공지 연동 테스트 100% 통과! <<<")

def test_campus_map_api():
    # 배재대학교 맵 데이터 테스트
    pcu_res = client.get("/api/university/campus-map?school_name=배재대학교")
    assert pcu_res.status_code == 200
    pcu_data = pcu_res.json()["campus_map"]
    assert "스마트ICT관" in [b["name"] for b in pcu_data["buildings"]]
    assert "map_links" in pcu_data

    # 충남대학교 맵 데이터 테스트
    cnu_res = client.get("/api/university/campus-map?school_name=충남대학교")
    assert cnu_res.status_code == 200
    cnu_data = cnu_res.json()["campus_map"]
    assert "공과대학 1호관" in [b["name"] for b in cnu_data["buildings"]]

    # 서울대학교 맵 데이터 테스트
    snu_res = client.get("/api/university/campus-map?school_name=서울대학교")
    assert snu_res.status_code == 200
    snu_data = snu_res.json()["campus_map"]
    assert "신공학관 (301동)" in [b["name"] for b in snu_data["buildings"]]

    # 일반 대학교 맵 데이터 테스트
    gen_res = client.get("/api/university/campus-map?school_name=한국공학대학교")
    assert gen_res.status_code == 200
    gen_data = gen_res.json()["campus_map"]
    assert len(gen_data["buildings"]) > 0
    print(">>> 전국 대학교 캠퍼스 맵 API 테스트 100% 통과! <<<")

if __name__ == "__main__":
    test_course_lifecycle_and_enrollment()
    test_campus_map_api()
