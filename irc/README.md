# Simple IRC Client for ZX-Spectrum

This is client works on any zx spectrum with AY-chip and compatible computers and simple WiFi shield.

## Requirements

 * AY-3-8912
 * WiFi shield attached to it
 * WiFi settings stored via [iwconfig](https://github.com/nihirash/iwconfig)

## Usage

Just run tap-file and application starts and in dialog mode ask all necessary data.

For sending IRC commands used symbol '!' but not '/'. Cause it simpler to type from rubber keyboard.

There some shortcuts:

 * `!j #channel` - will joins specified channel
 * `!l` - will leave current channel(you must switch on channel what you want leave)
 * `!s #channel` or `!s user` - will sets current talk stream to channel or user.
 * `!m user and there goes your message` sends to `user` private message

 If you need send some other command just write it after bang, example: 
 
 ```
 !KICK user
 ```

 ## Legals

Some parts of code based of SIC(simple irc client/suckless irc client).

My code is public domain. 