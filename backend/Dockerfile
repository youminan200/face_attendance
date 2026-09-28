FROM python:3.11-slim

WORKDIR /app

# 시스템 의존성 설치
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 파이썬 패키지 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 애플리케이션 코드 복사
COPY . .

# 데이터 디렉토리 생성 (SQLite 영구 보관용)
RUN mkdir -p /app/data
ENV SQLITE_PATH=/app/data/face_attendance.db

# 포트 개방
EXPOSE 8000

# 헬스체크 정의
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Uvicorn 서버 실행 (0.0.0.0 바인딩)
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]
