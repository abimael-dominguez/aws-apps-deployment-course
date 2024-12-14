# Use Python 3.8 slim image as base to minimize size
FROM python:3.8-slim

# Set working directory in container
WORKDIR /app

# Copy requirements first to leverage Docker cache
COPY ./requirements.txt .
# Install dependencies
RUN pip install --no-cache-dir -r ./requirements.txt

# Copy all application files
COPY . .

# Expose port 8000 for FastAPI
EXPOSE 8000

# Command to run the application
# --host 0.0.0.0 allows external access
# --port 8000 specifies the port number
CMD ["uvicorn", "retail_store_api:app", "--host", "0.0.0.0", "--port", "8000"]
