import asyncio
import datetime
import json
import logging
import nats
import sys

logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.INFO)

async def publish():

    # server = "tls://connect.ngs.global:4222"
    server = "tls://demo.nats.io:4443"
    creds = "/tmp/user.creds"
    subject = "messages"

    logger.info("Connecting to NATS server")
    # nc = await nats.connect(server, user_credentials=creds)
    nc = await nats.connect(server)

    # Define json payload to be sent
    payload = {
        "type": "alert",
        "ts": datetime.datetime.now().isoformat()
    }

    # Sending payload
    try:
        await nc.publish(
            subject=subject,
            payload=json.dumps(payload).encode()
        )
    except Exception as err:
        logger.error("payload could not be sent: {}".format(err))
    finally:
        await nc.close()

def main(request):
    logger.info("Running main function")
    asyncio.run(publish())
    return {}

