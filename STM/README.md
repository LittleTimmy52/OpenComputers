# SecureTerminalMessage
## Purpose
This program will open a very secure connection between 2 computers and sent messages between them.

## What I have
STMHost

STMClient

## Two versions
The modem api has the function send, this means only the computer specified can rcieve data,
broadcast does not have this, so broadcast needs to be encrypted, send does not, so this is the
difference, they both do the same thing but in a different way. Send is more secure and does not
even need a data card, but broadcast does and makes use of encryption to keep messages secure and
uses broadcast only