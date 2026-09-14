FROM python:3.11-slim-bookworm as builder
RUN python -m venv /venv
ENV PATH="/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
&& pip install --no-cache-dir -r requirements.txt

FROM python:3.11-slim-bookworm
COPY --from=builder /venv /venv 
ENV PATH="/venv/bin/$PATH"
RUN 
WORKDIR /app
COPY app.py .
CMD ["python","app.py"]