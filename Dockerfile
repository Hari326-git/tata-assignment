FROM python:3.9-slim

WORKDIR /app
RUN pip3 install flask

COPY . .

CMD ["python", "app.py"]
