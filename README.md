## cdevtools - Sublime Text texteditor

---
### cdevtools script

<code>scp dev username@yoursite.dev:~/bin/dev</code>
<code>chmod +x ~/bin/dev</code>

####Or create alias

run cmd
<code>alias mycdev='~/bin/dev'</code> 
and add to
<code>~/.bashrc </code>
#### SSH Tunnel

Auto connect config

<code>vi ~/.ssh/config</code>

<pre>
Host yoursite.dev
  Hostname 101.0.1.99
  RemoteForward 52698 127.0.0.1:52698
</pre>

Manual connect

<code>ssh -R 52698:localhost:52698 username@yoursite.dev</code>


####RSub plugin and RMate script
- install Sublime Text2/3 rsub package 
- add rmate script to remote server
- <code>scp rmate username@yoursite.dev:~/bin/rmate</code>
- <code>chmod +x ~/bin/rmate</code>

#####Or create alias

run cmd
<code>alias myvim='~/bin/rmate'</code>and add to
<code>~/.bashrc </code>