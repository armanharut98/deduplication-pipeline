exports.handler = async (event) => {
    console.log("event: ", event)
    for (const record of event.Records) {
        console.log("record: ", record)
        if (record.eventName === "INSERT") {
            console.log(`New event added: ${JSON.stringify(record.dynamodb.NewImage)}`)
        }
    }
}
