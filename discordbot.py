# discordbot v.0.2
# © 2018-2019 oMeN23
import sys
import asyncio
import discord

if len(sys.argv) < 3:
  exit(1)  

client = discord.Client()
token = '' # string
vodchannel = 12345678 # integer

@client.event
async def on_ready(): 
  await client.get_channel(vodchannel).send('{} update: {}'.format(sys.argv[1], sys.argv[2]))      
  await client.close()

client.run(token, bot=False)
