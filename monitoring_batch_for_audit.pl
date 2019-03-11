#!/usr/bin/perl
use DBI;
use lib qw(/etc/nwzdb /usr/local/lib/perl);
use DBConf;
use Mail::Mailer;
use POSIX;

##This script collect the history of DB user who retrieved our site user's information.
#After that, each server manages receive an audit email automatically.

while ( ($tns,$value) =  each %dbconf)
{
 if ($tns eq 'HANOI'){

 $username = $value->{'username'};
 $password = $value->{'password'};

 my $dbh;
 if($dbh = DBI->connect("dbi:Oracle:$tns",$username,$password,{AutoCommit=>0, ora_envhp=>0}) )
 {
	#print "Connected to $tns\n";
 }
 else
 {
	print "Connection attempt to $tns is failed , Skip\n";
	next;
 }

$tsql = <<EOF;
SELECT * FROM (
	SELECT TIMESTAMP,db_user,os_user,object_name,sql_text,sql_bind,decode(host,'idb6','HANOI','idb10','BACKUP_HANOI','ETC') 
	FROM nwidba.fga_audit_log  WHERE TIMESTAMP>SYSDATE-1 AND os_user!='bi' AND db_user!='NWIDBI' 
	group by TIMESTAMP,db_user,os_user,userhost,object_name,sql_text,sql_bind,host ORDER BY TIMESTAMP DESC)
WHERE ROWNUM<=100
EOF

$usql=<<EOA;
SELECT distinct os_user
FROM
  (SELECT *
  FROM nwidba.fga_audit_log
  WHERE TIMESTAMP>SYSDATE-1
  AND os_user!   ='bi'
  AND db_user!   ='NWIDBI'
  ORDER BY TIMESTAMP DESC
  )
WHERE ROWNUM<=100
EOA

	my $s = $dbh->prepare($tsql);
	$s->execute();
	while (($time,$db_user,$os_user,$userhost,$object,$text,$bind,$host) = $s->fetchrow_array())
	{
		push @audit_array,(["$time","$db_user","$os_user","$userhost","$object","$text","$bind","$host"]);
	 }

 $s->finish();

	my $x = $dbh->prepare($usql);
    $x->execute();
    while (($os_user) = $x->fetchrow_array())
    {
        $os_user_list=$os_user_list.",$os_user\@neowiz\.com";
     }

 $x->finish();
 $dbh->disconnect; 

	 $body.="<HEAD>
			<META HTTP-EQUIV='Cache-Control' CONTENT='no-cache'>
			<META HTTP-EQUIV='Progma' CONTENT='no-cache'>
			<body>
			<p>This is the history of personal information table retrieved from the HanoiDB and from The HanoiBackDB for the last 1 day..</p>
			<p>The server manager will automatically receive emails.</p>";
	 $body.="<TABLE border=1 width=700 style='word-break: break-all;word-wrap: break-word' style='table-layout:fixed;'><TR><TH>execute time</TH><TH>user</TH><TH>OS user</TH><TH>table name</TH><TH>SQL statement</TH><TH>BIND</TH><TH align=center>DB name</TH></TR>";

	for $i (0 ..$#audit_array){
		$sql=$audit_array[$i][4];
		$sql=~s/","/, /g;
		$sql=~s/"//g;
		push @body_char ,"<tr><TD>$audit_array[$i][0]</TD><TD>$audit_array[$i][1]</td><TD>$audit_array[$i][2]</TD> <TD>$audit_array[$i][3]</TD><TD><table width=300 cellpadding=1 style='table-layout:fixed;'><tr><td> <p style='font-size:8pt;word-break: break-all'>$sql</p></td></tr> </table></TD><TD>$audit_array[$i][5]</TD><TD>$audit_array[$i][6]</td></tr>";
	}
		$audit_mail=join("\n",@body_char);
		$body.=$audit_mail;

$css.="<STYLE type=text/css>
BODY {
    font : 11pt Arial, Helvetica, sans-serif;
    color : black;
/*  background : White; */
}

.wrap {word-break:break-all} 

P {
    font : 10pt Arial, Helvetica, sans-serif;
    color : black;
/*  background : White; */
}

FORM {
    font : 10pt Arial, Helvetica, sans-serif;
    color : black;
/*  background : White; */

}

TEXTAREA {
    font : 10pt \"Courier New\", Courier, monospace;
}

INPUT {
    font : 10pt Arial, Helvetica, sans-serif;
}

LABEL{
    font: 10pt Arial, Helvetica, sans-serif;
}

TH {
    font : bold 10pt Arial, Helvetica, sans-serif;
    color : #336699;
    background : #cccc99; */
    padding : 0px 0px 0px 0px;
}

TABLE, TR, TD {
    font : 8pt Arial, Helvetica, sans-serif;
    color : Black;
    background : #f7f7e7;
    padding : 0px 0px 0px 0px;
    margin : 0px 0px 0px 0px;
}
P.sql {
    font-size : 8pt;
    width : 300;
}

H1 {
    font: 16pt Arial, Helvetica, Geneva, sans-serif;
    color : #336699;
/*  background-color : White; */
    border-bottom : 1px solid #cccc99;
    margin-top : 0pt;
    margin-bottom : 0pt;
    padding : 0px 0px 0px 0px;
}

H2 {
    font: bold 10pt Arial, Helvetica, Geneva, sans-serif;
    color:#336699;
/*  background-color : White;*/
    margin-top : 4pt;
    margin-bottom : 0pt;
}

.tablePlusUIHead {
    font: bold 10pt Arial, Helvetica, sans-serif;
    color: #336699;
/*  background: White; */
    text-align : left;
    padding : 0px 0px 0px 0px;
    margin : 0px 0px 0px 0px;
}

.tablePlusUI {
    font : 10pt Arial, Helvetica, sans-serif;
    color : Black;
    /*background : White; */
    padding : 0px 0px 0px 0px;
    margin : 0px 0px 0px 0px;
}

.globalButton {
    font : 9pt Arial, Helvetica, sans-serif;
    color : #663300;
    background : #ffffff;
    text-align : center;
    margin-top : 0pt;
    margin-bottom : 0pt;
    vertical-align : top;
}

.globalButtonInactive {
    font : 9pt Arial, Helvetica, sans-serif;
    color : #000000;
    background : #ffffff;
    text-align : center;
    margin-top : 0pt;
    margin-bottom : 0pt;
    vertical-align : top;
}

 A:LINK, A:VISITED, A:ACTIVE, A, .breadCrumbs {
    font : 9pt Arial, Helvetica, sans-serif;
    color : #663300;
/*  background : #ffffff; */
    margin-top : 0pt;
    margin-bottom : 0pt;
    vertical-align : top;
}

.breadCrumbsInactive {
    font : 9pt Arial, Helvetica, sans-serif;
    color : #000000;
    background : #ffffff;
    margin-top : 0pt;
    margin-bottom : 0pt;
    vertical-align : top;
}

.labelHead {
    font : 10pt Arial, Helvetica, Geneva, sans-serif;
    color : #000000;
    background : #ffffff;
    text-align : right;
}

.ski {
    font : 9pt Arial, Helvetica, sans-serif;
    color: Black;
/*  background : White; */
    border-top : 1px solid #cccc99;
    text-align : right;
    margin : 14px 0px 0px 0px;
    padding : 12px 0px 0px 0px;
}

</STYLE>";


        $mail = Mail::Mailer->new("sendmail");
        $subj = 'The list of who retrieved user''s information.';

		$body.="</TABLE></body>";
            $mail->open({From => 'colasarang@neowiz.com',
                     To =>$teamDL.$os_user_list,
                     'Content-type'=> 'text/html; charset=euc-kr',
                     Subject => $subj
            }) or die "Can't open: $!\n";

        print $mail $css.$body;
        $mail->close();
 $dbh->disconnect;

}
}
