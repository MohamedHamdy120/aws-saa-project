from dotenv import load_dotenv
import os
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import text
from datetime import datetime
from flask import Flask, request, jsonify

load_dotenv()
DATABASE_URL=os.getenv("DATABASE_URL")
SQS_QUEUE_URL=os.getenv("SQS_QUEUE_URL")
app=Flask(__name__)
sqs = boto3.client("sqs")

app.config['SQLALCHEMY_DATABASE_URI']=DATABASE_URL
app.config['SQLALCHEMY_TRACK_MODIFICATIONS']=False
db=SQLAlchemy(app)

class Message(db.Model):
    id= db.Column(db.Integer, primary_key=True)
    name=db.Column(db.String(100),nullable=False)
    message=db.Column(db.Text, nullable=False)
    timestamp=db.Column(db.DateTime, default=datetime.utcnow)

@app.route('/health')
def health():
    try:
        db.session.execute(text("SELECT 1"))
        return {
            "status": "healthy",
            "database": "connected"
        },200
    except Exception:
        db.session.rollback()
        return {
            "status": "unhealthy",
            "database": "disconnected"
        },503


@app.route('/messages', methods=['GET'])
def get_messages():
    messages=Message.query.order_by(Message.timestamp.desc()).all()
    result=[]
    for msg in messages:
        result.append(
            {
                "id":msg.id,
                "name":msg.name,
                "message":msg.message,
                "timestamp":msg.timestamp.isoformat()
            }
        )
    return jsonify(result)

@app.route('/messages',methods=['POST'])
def add_message():
    data=request.get_json()
    if not data:
        return jsonify({"error":"Invalid request"}),400
    
    name=data.get("name")
    message=data.get("message")

    if not name or not message:
        return jsonify({"error":"name and messages fields are required"}),400
    

    new_message=Message(name=name,message=message)
    db.session.add(new_message)
    db.session.commit()
    try:
        sqs.send_message(
        QueueUrl=SQS_QUEUE_URL ,
        MessageBody=json.dumps({
            "event": "new_entry",
            "id": new_message.id,
            "name": new_message.name
        }))

    except Exception as e:
        app.logger.error(f"connection to the sqs queue failed :{e}")
    return jsonify(
        {
            "id":new_message.id,
            "name":new_message.name,
            "message":new_message.message,
            "timestamp":new_message.timestamp.isoformat()
        }
    ),201



if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(host='0.0.0.0', port=5000)