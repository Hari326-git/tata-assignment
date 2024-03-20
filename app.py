from flask import Flask, request

app = Flask(__name__)

@app.route('/')
def welcome():
    user_agent = request.headers.get('User-Agent')
    return f"<h1>Welcome to 2022!</h1><p>Your User-Agent is: {user_agent}</p>"

if __name__ == '__main__':
    app.run(debug=True)
