FROM python:3.11-slim-bookworm as builder
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.11-slim-bookworm
COPY --from=builder /install /usr/local 
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/* \
&& pip install -- no-cache-dir -- upgrade pip setuptools wheel
WORKDIR /app
COPY app.py .
CMD ["python","app.py"]