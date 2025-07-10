FROM python:3.13-slim-bookworm

LABEL tk.title="demo-app" \
      tk.description="A simple Flask demo app" \
      tk.version="1.0" \
      tk.maintainers="tomislav.kostic@email.com"

ENV PYTHONUNBUFFERED=1
ENV PATH="/app/venv/bin:$PATH"

RUN apt-get update && apt-get install -y --no-install-recommends build-essential curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt ./
RUN python -m venv venv \
    && . venv/bin/activate \
    && pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

COPY . .

RUN adduser --disabled-password appuser
USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:8080/healthy || exit 1

CMD ["python", "./app.py"]
