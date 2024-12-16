const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { PutCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({ region: "us-east-1" });
const tableName = process.env.TABLE_NAME

exports.handler = async (event) => {
    console.log("event: ", event, event.Records.length)
    const result = []
    for (const record of event.Records) {
        console.log("record :", record)
        const body = JSON.parse(record.body)
        console.log("body :", body)
        const command = new PutCommand({
            TableName: tableName,
            Item: body,
            ConditionExpression: "attribute_not_exists(event_id)"
        })
        try {
            const response = await client.send(command);
            console.log(response);
            result.push(response)
        } catch (exception) {
            if (exception.name === "ConditionalCheckFailedException") {
                console.log(`Duplicate event: ${body}`)
            } else {
                console.log(`Unable to save event to DB. Event: ${body}`)
            }
        }
    }
    console.log(`Processed ${result.length} messages.`)
    return result;
}
