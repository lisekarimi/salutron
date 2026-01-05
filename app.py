from flask import Flask, render_template
from openai import OpenAI
import os

app = Flask(__name__)

# Initialize OpenAI client
openai_client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))


def call_openai(prompt: str) -> str:
    """Call OpenAI API"""
    try:
        response = openai_client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=100,
            temperature=0.9
        )
        return response.choices[0].message.content
    except Exception as e:
        print(f"OpenAI error: {e}")
        return f"ERROR: {str(e)}"


@app.route('/')
def hello():
    prompt = "Greet someone warmly and mention this is a learning project built to master Terraform, Docker, and AWS, GCP and Azure. Keep it fun and under 20 words!"
    greeting = call_openai(prompt)
    return render_template('index.html', greeting=greeting)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
