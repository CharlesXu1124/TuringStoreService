import asyncio
from aio_pika import connect, IncomingMessage
import serial

s = serial.Serial('COM4',9600, timeout=.1)

async def on_message(message: IncomingMessage):
    """
    on_message doesn't necessarily have to be defined as async.
    Here it is to show that it's possible.
    """
    print(" [x] Received message %r" % message)
    print("Message body is: %r" % message.body)
    # send the command for grabbing!
    s.write('1'.encode())
    print("Before sleep!")
    await asyncio.sleep(1000)  # Represents async I/O operations
    print("After sleep!")


async def main(loop):
    # Perform connection
    # please use your own rabbitMQ server
    connection = await connect(
        "amqp://user2:rtc2021@168.61.18.117", loop=loop
    )

    # Creating a channel
    channel = await connection.channel()

    # Declaring queue
    queue = await channel.declare_queue("hello")

    # Start listening the queue with name 'hello'
    await queue.consume(on_message, no_ack=True)


if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.create_task(main(loop))

    # we enter a never-ending loop that waits for data and
    # runs callbacks whenever necessary.
    print(" [*] Waiting for messages. To exit press CTRL+C")
    loop.run_forever()