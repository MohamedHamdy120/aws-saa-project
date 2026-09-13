FROM python:3.11-slim-bookworm as builder
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.11-slim-bookworm
COPY --from=builder /install /usr/local 
WORKDIR /app
COPY app.py .
CMD ["python","app.py"]