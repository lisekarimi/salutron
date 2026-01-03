from flask import Flask
from openai import OpenAI
import os

app = Flask(__name__)
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

@app.route('/')
def hello():
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "user", "content": "Say hello in a creative and unique way. Just one short sentence."}
        ]
    )

    return f"<h1>{response.choices[0].message.content}</h1>"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
