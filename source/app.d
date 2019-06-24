import vibe.http.server;
import vibe.core.log;
import vibe.core.core;
import std.stdio;
import std.file;
import std.conv;
import std.string;
import std.path;
import std.getopt;
import std.array;
import core.stdc.stdlib;
string dir=".";
enum html_pre=`<html>
<head>
<title>Directory listing for /</title>
<style>
.even-dir { background-color: #efe0ef }
.even { background-color: #eee }
.odd-dir {background-color: #f0d0ef }
.odd { background-color: #dedede }
.icon { text-align: center }
.listing {
    margin-left: auto;
    margin-right: auto;
    width: 50%;
    padding: 0.1em;
    }

body { border: 0; padding: 0; margin: 0; background-color: #efefef; }
h1 {padding: 0.1em; background-color: #777; color: white; border-bottom: thin white dashed;}

</style>
</head>

<body>
<h1>Directory listing for /</h1>

<table>
    <thead>
        <tr>
            <th>Filename</th>
	</tr>
   </thead>
   <tbody>`;
enum html_post=`   </tbody>
</table>

</body>
</html>`;
void main(string[] args)
{
	ushort port=8080;
	auto helpInfo=getopt(args,"dir",&dir,"port",&port);
	if(helpInfo.helpWanted)
	{
		defaultGetoptPrinter("dfileserver help:",helpInfo.options);
		exit(0);
	}
	if(!exists(dir) || !isDir(dir))
	{
		writefln("Warning dir %s doesn't exist or is not a dir, use current dir instead!",dir);
	}
	auto settings = new HTTPServerSettings;
	settings.port = port;
	listenHTTP(settings, &dirlist);
	logInfo("dfileserver is started!");
	runApplication();
}

void dirlist(HTTPServerRequest req, HTTPServerResponse res)
{
	string adir=std.array.array(dir.asAbsolutePath());
	auto rp=req.requestURI.stripLeft("/");
	string pp=buildPath(dir,rp);
	debug writeln("adir:"~adir);
	if(!exists(pp))
	{
		res.writeBody("Oops!, the request url "~pp~ " doesn't exists!");
	}
	else if(isFile(pp))
	{
		res.writeBody(pp.readText());
	}
	else
	{
		res.contentType("text/html; charset=UTF-8");
		string tlist="";
		int i=0;
		foreach(string name;dirEntries(pp,SpanMode.shallow))
		{
		    debug  writeln("entry:"~name);

			if(i==0)
			{
				
			tlist=tlist~`<tr class="` ~ ((i%2==0)? "even":"odd") ~`"><td><a href="/`~pp.asRelativePath(adir).array~"/.."~`">..</a></td></tr> `~"\n";
				i++;
			}
			tlist=tlist~`<tr class="` ~ ((i%2==0)? "even":"odd") ~`"><td><a href="/`~name.asRelativePath(adir).array~`">`~name.baseName~`</a></td></tr> `~"\n";
			i++;
		}	
		res.writeBody(html_pre~tlist~html_post);	
	}
}
