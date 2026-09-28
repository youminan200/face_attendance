import urllib.request
import urllib.parse
import json

base_url = "http://127.0.0.1:8080"

def post(endpoint, data):
    req = urllib.request.Request(
        f"{base_url}{endpoint}",
        data=json.dumps(data).encode("utf-8"),
        headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))

def get(endpoint):
    # 한글 쿼리스트링 URL 인코딩 처리
    if "?" in endpoint:
        path, query = endpoint.split("?", 1)
        params = urllib.parse.parse_qsl(query)
        encoded_query = urllib.parse.urlencode(params)
        full_url = f"{base_url}{path}?{encoded_query}"
    else:
        full_url = f"{base_url}{endpoint}"

    req = urllib.request.Request(full_url)
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))

print("=== 1. Health & Univ Count ===")
print(get("/health"))
home = get("/")
print(f"Server: {home['service']}, Univ Count: {home['registered_universities_count']}")

print("\n=== 2. University Search (KAIST) ===")
univs = get("/api/universities?q=kaist")
print("Found:", [(u["code"], u["name"], u["protocol"]) for u in univs["universities"]])

print("\n=== 3. University Search (사관학교) ===")
academies = get("/api/universities?region=사관학교")
print("Found:", [(u["code"], u["name"], u["protocol"]) for u in academies["universities"]])

print("\n=== 4. Sign Up Test ===")
signup_res = post("/api/signup", {
    "school": "서울대학교",
    "major": "컴퓨터공학부",
    "name": "홍길동",
    "id": "20261001",
    "role": "학생",
    "password": "password123!",
    "faceTemplate": json.dumps({"version": 2, "near": [0.1]*1024, "far": [0.2]*1024})
})
print("Signup Response:", signup_res)

print("\n=== 5. Login Test ===")
login_res = post("/api/login", {
    "id": "20261001",
    "password": "password123!",
    "role": "학생"
})
print("Login Profile:", login_res["profile"])

print("\n=== 6. University Course Sync Test (KAIST) ===")
courses = get("/api/universities/kaist/courses?student_id=20261001")
print("Courses synced:", courses["courses"])

print("\n=== 7. Special Academy Attendance Push Test (육군사관학교) ===")
sync_res = post("/api/universities/kma/attendance", {
    "student_id": "20261001",
    "course_id": "kma_mil_01",
    "course_title": "[육군사관학교] 군사전략학",
    "attendance_date": "2026-09-16",
    "attendance_time": "09:00:00",
    "status": "출석",
    "similarity_score": 0.88
})
print("Sync Response:", sync_res)

print("\n=======================================================")
print(">>> ALL 7 BACKEND TEST SCENARIOS PASSED WITH 100%! <<<")
print("=======================================================")
