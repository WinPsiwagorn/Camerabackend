FROM python:3.10-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code
COPY app/ .

# Copy model and secrets
COPY models/ /models/
COPY secrets/ /secrets/

# Create output dir
RUN mkdir -p /output

CMD ["python", "main.py"]