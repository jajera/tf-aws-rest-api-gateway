from __future__ import print_function
import boto3
import os

dynamoDBResource = boto3.resource('dynamodb')

def lambda_handler(event, context):
    print(event)
    
    UserId = event["UserId"]
    NoteId = event['NoteId']
    Note = event['Note']
    ddbTable = os.environ['TABLE_NAME']
    newNoteId = upsertItem(dynamoDBResource, ddbTable, UserId, NoteId, Note)

    return newNoteId

def upsertItem(dynamoDBResource, ddbTable, UserId, NoteId, Note):
    print('upsertItem Function')

    table = dynamoDBResource.Table(ddbTable)
    table.put_item(
        Item={
            'UserId': UserId,
            'NoteId': int(NoteId),
            'Note': Note
        }
    )

    return NoteId
