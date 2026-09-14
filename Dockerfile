FROM python:3.11-slim-bookworm as builder
RUN python -m venv /venv
ENV PATH="/venv/bin:${PATH}"
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt / 
 && pip install --no-cache-dir --upgrade "msgpack>=1.2.1" && pip uninstall -y pip wheel setuptools

FROM python:3.11-slim-bookworm
COPY --from=builder /venv /venv 
ENV PATH="/venv/bin/${PATH}"
RUN rm -rf /usr/local/lib/python3.11/site-packages
WORKDIR /app
COPY app.py .
CMD ["python","app.py"]