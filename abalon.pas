{

  ABALON - a game of robust group movements from the ancient Spain

  Version 1.0  (C) 1992.11.01. Peter Csurgay  (361)-2764845

  Date of last edition: 1992.11.11.

  - can't understand sideways group movements

}

uses
  crt, graph, dos, p_mouse, d_kijelz;

type
  stt=array[-5..5,-5..5] of integer;
  sct=array[1..2] of integer;

const
  logoline='Abalon, Version 1.0, Copyright (C) 1992, Peter Csurgay  (361)-2764845';
  imgfilename='abalon.img';
  boardfilename='abalon.brd';
  ega:array[0..15] of integer = (0,1,2,3,4,5,20,7,56,57,58,59,60,61,62,63);
  kcob=8; bl=6; bl2=1; wh=13; hi=15; bkfill=7; bubfill=1;
  co_spot:array[0..2] of integer = (kcob,bl2,wh);
  c_co_bk=26; c_co_wh=45; c_co_bl=0; c_co_hi=63;
  r=235; cx=320; cy=210; rd=50; rr=20; bubd=7; bubr=2;
  gy3p2=8.6602540379E-01;
  firstst:stt=((3,3,3,3,3,3,3,3,3,3,3),
               (3,3,3,3,3,0,0,0,2,2,3),
               (3,3,3,3,0,0,0,0,2,2,3),
               (3,3,3,0,0,0,0,2,2,2,3),
               (3,3,1,0,0,0,0,2,2,2,3),
               (3,1,1,1,0,0,0,2,2,2,3),
               (3,1,1,1,0,0,0,0,2,3,3),
               (3,1,1,1,0,0,0,0,3,3,3),
               (3,1,1,0,0,0,0,3,3,3,3),
               (3,1,1,0,0,0,3,3,3,3,3),
               (3,3,3,3,3,3,3,3,3,3,3));
  maxkj=7;
  c_kj:array[1..maxkj,1..6] of integer = (
    (6,10,10,6,0,0), (5,10,64,5,0,0), (3,10,108,5,0,0),
    (6,634,10,5,1,0), (5,634,45,5,1,0),
    (6,634,90,5,1,0), (5,634,125,5,1,0) );
  outx=525; outy=458;
  maxbut=9;
  bx=13; by=437; bw=50; bh=30; bd=55;
  b_exit=1; b_new=2;
  b_save=3; b_load=4; b_bb=5; b_lock=6; b_ff=7; b_b=8; b_f=9;
  maxmaxstep=1000;

var
  fil:text;
  image:file;
  screen:array[0..2000] of word absolute $b800:$0000;
  screensave:array[0..2000] of word;
  cursorsavex:integer;
  cursorsavey:integer;
  p_img:array[0..2] of pointer;
  s_image:word;
  names:array[1..2] of string[6];
  stopper:array[0..2] of string[6];
  mins,secs,s10s:array[0..2] of word;
  yea,mon,day,dow,hou,min,sec,s10,olds10:word;
  pl,oldpl,step,maxstep:integer;
  sc:sct;
  st:stt;
  mx,my,mz:integer; {eger}
  c_cx:array[-4..4,-4..4] of integer;
  c_cy:array[-4..4,-4..4] of integer;
  ny:array[-4..4,-4..4] of real;
  tx:array[1..maxmaxstep] of integer;
  ty:array[1..maxmaxstep] of integer;
  tdx:array[1..maxmaxstep] of integer;
  tdy:array[1..maxmaxstep] of integer;
  tkil:array[1..maxmaxstep] of integer;
  tn:array[1..maxmaxstep] of integer;
  fastmode:boolean;
  needtime:boolean;
  ketyeg:boolean;

procedure wait(var c:char);
begin
  repeat until keypressed;
  c:=readkey;
end;

procedure beep;
begin
  sound(100); delay(30); nosound;
end;

procedure errorhalt(s:string);
var
  i:integer;
begin
  for i:=0 to 2 do freemem(p_img[i],s_image);
  closegraph;
  for i:=0 to 2000 do screen[i]:=screensave[i];
  gotoxy(cursorsavex,cursorsavey);
  if s<>'' then writeln(s);
  halt;
end;

function graphinit:boolean;
var gd,gm:integer;
begin
  detectgraph(gd,gm);
  initgraph(gd,gm,'');
  if gd<>9 then graphinit:=false else graphinit:=true;
end;

procedure getparameters;
const
  maxparam=1;
  s_usage='  Usage: abalon < time >';
var
  i,j:integer;
  paramb:array[1..maxparam] of boolean;
  params:array[1..maxparam] of string;
  voltilyen:boolean;
begin
  needtime:=false;
  params[1]:='time';
  for i:=1 to maxparam do paramb[i]:=false;
  for i:=1 to paramcount do begin
    voltilyen:=false;
    for j:=1 to maxparam do begin
      if paramstr(i)=params[j] then begin
        params[j]:='popo';
        paramb[j]:=true;
        voltilyen:=true;
      end;
    end;
    if not voltilyen then errorhalt(s_usage);
  end;
  if paramb[1] then needtime:=true;
end;

procedure dates;
begin
  getdate(yea,mon,day,dow);
end;

procedure timeswrite(p:integer);
begin
  m_off;
  if p=0 then begin
    kij(' ',2);
    kij(' ',5);
    kij(' ',7);
  end;
  if p=1 then begin
    kij(stopper[0],2);
    kij(stopper[pl],3+pl*2);
  end;
  if p=2 then begin
    kij(stopper[0],2);
    kij(stopper[1],5);
    kij(stopper[2],7);
  end;
  m_on;
end;

procedure timesget;
var num:string;
begin
  gettime(hou,min,sec,s10);
  if pl<>oldpl then begin
    s10s[oldpl]:=s10s[oldpl]+(s10-olds10) mod 100;
    if s10s[oldpl]>100 then begin
      inc(secs[0]); if secs[0]=60 then begin
        secs[0]:=0; inc(mins[0]);
      end;
      inc(secs[oldpl]);
      s10s[oldpl]:=0;
      if secs[oldpl]=60 then begin secs[oldpl]:=0; inc(mins[oldpl]); end;
      str(mins[oldpl],stopper[oldpl]);
      str(secs[oldpl],num); if num[0]=#1 then num:='0'+num;
      stopper[oldpl]:=stopper[oldpl]+' '+num;
      str(mins[0],stopper[0]);
      str(secs[0],num); if num[0]=#1 then num:='0'+num;
      stopper[0]:=stopper[0]+' '+num;
      if needtime then timeswrite(2);
    end;
    oldpl:=pl;
  end
  else begin
    s10s[pl]:=s10s[pl]+(s10-olds10) mod 100;
    if s10s[pl]>100 then begin
      inc(secs[0]); if secs[0]=60 then begin
        secs[0]:=0; inc(mins[0]);
      end;
      inc(secs[pl]);
      s10s[pl]:=0;
      if secs[pl]=60 then begin secs[pl]:=0; inc(mins[pl]); end;
      str(mins[pl],stopper[pl]);
      str(secs[pl],num); if num[0]=#1 then num:='0'+num;
      stopper[pl]:=stopper[pl]+' '+num;
      str(mins[0],stopper[0]);
      str(secs[0],num); if num[0]=#1 then num:='0'+num;
      stopper[0]:=stopper[0]+' '+num;
      if needtime then timeswrite(2);
    end;
  end;
  olds10:=s10;
end;

function inputname(var name:string):boolean;
var
  n,mx,my,mz:integer;
  c:char;
begin
  repeat
    kij(name,1); delay(100);
    kij(' ',1); delay(70);
    m_getstatus(mx,my,mz);
  until keypressed or (mz=2);
  if keypressed then begin
    name:='      '; n:=0;
    kij(name,1);
    repeat
      kij(name,1);
      wait(c);
      if c=#8 then if n>0 then begin name[n]:=' '; n:=n-1; end
                   else beep
      else if c>#31 then if n<6 then begin n:=n+1; name[n]:=c; end
                         else beep;
    until (c=#13) or (c=#27);
    if c=#27 then inputname:=false else inputname:=true;
  end
  else inputname:=false;
  kij('ABALON',1);
end;

function existfile(filename:string):boolean;
var f:text;
  begin
    {$I-}
    assign(f,filename);
    reset(f);
    close(f);
    {$I+}
    existfile:=(IOResult=0);
  end;

procedure getcenters;
var x,y:integer;
begin
  for x:=-4 to 4 do for y:=-4 to 4 do begin
    c_cx[x,y]:=round(cx+x*rd+y*rd div 2);
    c_cy[x,y]:=round(cy+y*rd*gy3p2);
  end;
end;

procedure getnyoms;
var
  x,y:integer;
begin
  for x:=-4 to 4 do for y:=-4 to 4 do
    ny[x,y]:=1.0*(c_cx[x,y]-cx)*(c_cx[x,y]-cx)+
             1.0*(c_cy[x,y]-cy)*(c_cy[x,y]-cy);
end;

procedure spot(x,y,mi:integer);
begin
  if mi=0 then begin
    setcolor(kcob);
    circle(c_cx[x,y],c_cy[x,y],rr-3);
    setfillstyle(bkfill,bl);
    floodfill(c_cx[x,y],c_cy[x,y],kcob);
  end
  else begin
    setcolor(co_spot[mi]);
    setfillstyle(1,co_spot[mi]);
    fillellipse(c_cx[x,y],c_cy[x,y],rr,rr);
    setcolor(15);
    setfillstyle(bubfill,15);
    arc(c_cx[x,y],c_cy[x,y],40,100,rr-4);
    circle(c_cx[x,y]+bubd,c_cy[x,y]+bubd,bubr);
    floodfill(c_cx[x,y]+bubd,c_cy[x,y]+bubd,15);
  end;
end;

procedure imgspot(x,y,mi:integer);
begin
  putimage(c_cx[x,y]-rr,c_cy[x,y]-rr,p_img[mi]^,0);
end;

procedure saveimages;
var
  i:integer;
begin
  for i:=0 to 2 do begin
    spot(0,0,i);
    getimage(cx-rr,cy-rr,cx+rr,cy+rr,p_img[i]^);
  end;
  assign(image,imgfilename); rewrite(image,1);
  for i:=0 to 2 do blockwrite(image,p_img[i]^,s_image);
  close(image);
end;

procedure cross(x,y:integer);
var u,v:integer;
begin
  u:=c_cx[x,y]; v:=c_cy[x,y];
  setwritemode(1);
  line(u-6,v,u+6,v);
  line(u,v-6,u,v+6);
  setwritemode(0);
end;

procedure initialize;
var
  i,j:integer;
begin
  randomize;
  getcenters;
  getnyoms;
  s_image:=imagesize(cx-rr,cy-rr,cx+rr,cy+rr);
  for i:=0 to 2 do getmem(p_img[i],s_image);
  if not existfile(imgfilename) then saveimages
  else begin
    assign(image,imgfilename); reset(image,1);
    for i:=0 to 2 do blockread(image,p_img[i]^,s_image);
    close(image);
  end;
  st:=firstst;
  d_kijelz_init;
  for i:=1 to maxkj do for j:=1 to 6 do kj[i,j]:=c_kj[i,j];
  for i:=0 to 2 do begin mins[i]:=0; secs[i]:=0; end;
  for i:=0 to 2 do stopper[i]:=' 0 00';
  names[1]:='PL 1'; names[2]:='PL 2';
  pl:=1; oldpl:=1; step:=1; maxstep:=1; sc[1]:=0; sc[2]:=0;
  fastmode:=false;
  ketyeg:=true;
end;

function buttonwas:integer;
var i,l,t,r,b:integer;
begin
  buttonwas:=0;
  for i:=1 to maxbut do begin
    l:=bx+(i-1)*bd; t:=by; r:=l+bw; b:=t+bh;
    if (mx>l) and (mx<r) and (my>t) and (my<b) then buttonwas:=i;
  end;
end;

procedure button(i,s:integer);
var
  l,t,r,b:integer;
  cok,cob:integer;
begin
  cok:=wh; cob:=bl;
  if i>0 then begin
    l:=bx+(i-1)*bd; t:=by; r:=l+bw; b:=t+bh;
    setfillstyle(1,cok); bar(l,t,r,b);
    setcolor(cob);
    l:=l+2*s; t:=t+2*s;
  end;
  case i of
    0: begin
  setfillstyle(1,bl); bar(9,433,507,471);
    end;
    b_save: begin
  setlinestyle(0,0,3);
  moveto(l+20,t+8); lineto(l+25,t+10); lineto(l+27,t+15);
  lineto(l+25,t+20); lineto(l+20,t+22); lineto(l+15,t+20);
  lineto(l+13,t+15); lineto(l+15,t+10); lineto(l+20,t+8);
  line(l+19,t+22,l+40,t+22);
  setlinestyle(0,0,1);
  moveto(l+30,t+9); lineto(l+40,t+9); lineto(l+35,t+19); lineto(l+30,t+9);
  setfillstyle(1,cob); floodfill(l+35,t+13,cob);
    end;
    b_load: begin
  setlinestyle(0,0,3);
  moveto(l+20,t+8); lineto(l+25,t+10); lineto(l+27,t+15);
  lineto(l+25,t+20); lineto(l+20,t+22); lineto(l+15,t+20);
  lineto(l+13,t+15); lineto(l+15,t+10); lineto(l+20,t+8);
  line(l+19,t+22,l+40,t+22);
  setlinestyle(0,0,1);
  moveto(l+30,t+18); lineto(l+40,t+18); lineto(l+35,t+9); lineto(l+30,t+18);
  setfillstyle(1,cob); floodfill(l+35,t+17,cob);
    end;
    b_b: begin
  moveto(l+33,t+8); lineto(l+17,t+15); lineto(l+33,t+22); lineto(l+33,t+8);
  setfillstyle(1,cob); floodfill(l+30,t+15,cob);
    end;
    b_f: begin
  moveto(l+17,t+8); lineto(l+33,t+15); lineto(l+17,t+22); lineto(l+17,t+8);
  setfillstyle(1,cob); floodfill(l+20,t+15,cob);
    end;
    b_bb:begin
  moveto(l+23,t+8); lineto(l+10,t+15); lineto(l+23,t+22); lineto(l+23,t+8);
  setfillstyle(1,cob); floodfill(l+20,t+15,cob);
  moveto(l+40,t+8); lineto(l+27,t+15); lineto(l+40,t+22); lineto(l+40,t+8);
  setfillstyle(1,cob); floodfill(l+35,t+15,cob);
    end;
    b_ff:begin
  moveto(l+10,t+8); lineto(l+23,t+15); lineto(l+10,t+22); lineto(l+10,t+8);
  setfillstyle(1,cob); floodfill(l+20,t+15,cob);
  moveto(l+27,t+8); lineto(l+40,t+15); lineto(l+27,t+22); lineto(l+27,t+8);
  setfillstyle(1,cob); floodfill(l+35,t+15,cob);
    end;
    b_lock: begin
  setfillstyle(1,cob);
  bar(l+19,t+8,l+23,t+22);
  bar(l+27,t+8,l+31,t+22);
    end;
    b_exit: begin
  setfillstyle(1,cob); bar(l+19,t+8,l+31,t+22);
  setcolor(hi); moveto(l+20,t+9); lineto(l+20,t+21);
  lineto(l+24,t+18); lineto(l+24,t+9); lineto(l+20,t+9);
  setfillstyle(1,hi); floodfill(l+23,t+10,hi);
    end;
    b_new: begin
  setcolor(cob); moveto(l+30,t+7); lineto(l+33,t+15);
  lineto(l+30,t+23); lineto(l+20,t+23); lineto(l+17,t+15);
  lineto(l+20,t+7); lineto(l+30,t+7);
  setfillstyle(1,kcob); floodfill(l+25,t+15,cob);
  setcolor(cob);
  moveto(l+21,t+8); lineto(l+29,t+8);
  moveto(l+21,t+9); lineto(l+29,t+9);
  moveto(l+21,t+10); lineto(l+29,t+10);
  moveto(l+20,t+11); lineto(l+30,t+11);
  moveto(l+23,t+12); lineto(l+27,t+12);
  setcolor(hi);
  moveto(l+21,t+21); lineto(l+29,t+21);
  moveto(l+21,t+20); lineto(l+29,t+20);
  moveto(l+20,t+19); lineto(l+30,t+19);
  moveto(l+24,t+18); lineto(l+26,t+18);
    end;
  end;
  l:=l-2*s; t:=t-2*s;
  if i>0 then if s=0 then begin
    setcolor(hi); line(l,t,l+bw,t); line(l,t,l,t+bh);
    setcolor(kcob); line(l+bw,t,l+bw,t+bh); line(l,t+bh,l+bw,t+bh);
  end
  else begin
    setcolor(kcob); line(l,t,l+bw,t); line(l,t,l,t+bh);
    setcolor(hi); line(l+bw,t,l+bw,t+bh); line(l,t+bh,l+bw,t+bh);
  end;
end;

procedure out_up(pl,sc:integer);
var x,y:integer;
begin
  x:=outx+pl*(rd-5); y:=outy-sc*(rd-5);
  setcolor(co_spot[pl]);
  setfillstyle(1,co_spot[pl]);
  fillellipse(x,y,rr,rr);
  setcolor(15);
  setfillstyle(bubfill,15);
  arc(x,y,40,100,rr-4);
  circle(x+bubd,y+bubd,bubr);
  floodfill(x+bubd,y+bubd,15);
end;

procedure out_down(pl,sc:integer);
var x,y:integer;
begin
  x:=outx+pl*(rd-5); y:=outy-sc*(rd-5);
  setcolor(kcob);
  setfillstyle(bkfill,bl);
  fillellipse(x,y,rr,rr);
end;

procedure out;
var pl,i:integer;
begin
  for pl:=1 to 2 do begin
    for i:=1 to sc[pl] do out_up(pl,i);
    for i:=sc[pl]+1 to 6 do out_down(pl,i);
  end;
end;

procedure state;
var
  x,y:integer;
begin
  for x:=-4 to 0 do for y:=-4-x to 4 do imgspot(x,y,st[x,y]);
  for x:=1 to 4 do for y:=-4 to 4-x do imgspot(x,y,st[x,y]);
end;

procedure board;
var
  a1,a2,i,x,y:integer;
  w1,w2:real;
begin
  setcolor(bl);
  for i:=0 to 5 do begin
    a1:=i*60;
    a2:=a1+60;
    w1:=a1*PI/180;
    w2:=a2*PI/180;
    line(cx+round(r*cos(w1)),cy+round(r*sin(w1)),
         cx+round(r*cos(w2)),cy+round(r*sin(w2)));
  end;
end;

function dostep(x3,y3,dx,dy:integer):integer;
var
  x,y,n,nw,nb,no:integer;
  kilok:boolean;
  kilokott:integer;
begin
  x:=x3; y:=y3; n:=0; nw:=1; nb:=0; no:=0;
  repeat
    x:=x+dx; y:=y+dy; inc(n);
    if (st[x,y]=st[x3,y3]) then if (nb=0) then inc(nw) else inc(no);
    if (st[x,y]=3-st[x3,y3]) then if (no=0) then inc(nb);
  until (st[x,y]=0) or (st[x,y]=3);
  if (nw>3) or (nw<=nb) or (no>0) then n:=0;
  if (st[x,y]=3) and (nb=0) then n:=0;
  if n>0 then begin
    if st[x,y]=3 then begin kilok:=true; kilokott:=st[x-dx,y-dy]; end
    else begin kilok:=false; kilokott:=0; end;
    repeat
      if st[x,y]<>3 then begin
        st[x,y]:=st[x-dx,y-dy];
        if not fastmode then imgspot(x,y,st[x,y]);
      end;
      x:=x-dx; y:=y-dy;
    until (x=x3) and (y=y3);
    st[x3,y3]:=0; if not fastmode then imgspot(x3,y3,0);
    if kilok then begin
      inc(sc[kilokott]);
      if not fastmode then out_up(kilokott,sc[kilokott]);
    end;
    tkil[step]:=kilokott;
  end;
  dostep:=n;
end;

procedure undostep(x3,y3,dx,dy,n:integer);
var
  x,y,i:integer;
  kilok:boolean;
begin
  x:=x3; y:=y3;
  for i:=1 to n do begin
    st[x,y]:=st[x+dx,y+dy];
    if st[x,y]=3 then kilok:=true else kilok:=false;
    if not kilok then if not fastmode then imgspot(x,y,st[x,y]);
    x:=x+dx; y:=y+dy;
  end;
  if kilok then begin
    st[x-dx,y-dy]:=tkil[step];
    if not fastmode then imgspot(x-dx,y-dy,tkil[step]);
    if not fastmode then out_down(tkil[step],sc[tkil[step]]);
    dec(sc[tkil[step]]);
  end
  else begin
    st[x,y]:=0; if not fastmode then imgspot(x,y,0);
  end;
end;

function ballwas(var x2,y2:integer):boolean;
var
  ban:boolean;
  x,y,hu,hv,r:integer;
begin
  r:=rr;
  ban:=false;
  for x:=-4 to 4 do for y:=-4 to 4 do begin
    hu:=c_cx[x,y]; hv:=c_cy[x,y];
    if (mx>hu-r) and (mx<hu+r) and (my>hv-r) and (my<hv+r) then begin
      x2:=x; y2:=y; ban:=true;
    end;
  end;
  if ban then if (st[x2,y2]<>pl) then ban:=false;
  ballwas:=ban;
end;

function one_step(x2,y2:integer):boolean;
var
  x,y,x3,y3,dx,dy,n:integer;
  hu,hv,r:integer;
  okstep,ban,kilok:boolean;
  kilokott:integer;
begin
  r:=rr;
    okstep:=true;
    cross(x2,y2); x3:=x2; y3:=y2;
    m_releasewait(mx,my);
    ban:=false;
    for x:=-4 to 4 do for y:=-4 to 4 do begin
      hu:=c_cx[x,y]; hv:=c_cy[x,y];
      if (mx>hu-r) and (mx<hu+r) and (my>hv-r) and (my<hv+r) then begin
        x2:=x; y2:=y; ban:=true;
      end;
    end;
    cross(x3,y3);
    if not ban then okstep:=false else begin
      dx:=x2-x3; dy:=y2-y3;
      if (dx=dy) or (abs(dx)>1) or (abs(dy)>1) then okstep:=false
      else n:=dostep(x3,y3,dx,dy);
      if n=0 then okstep:=false;
    end;
    if okstep then begin
      tx[step]:=x3; ty[step]:=y3; tdx[step]:=dx; tdy[step]:=dy; tn[step]:=n;
    end;
  one_step:=okstep;
end;

procedure led(n:integer; p:boolean);
const
  ledx:array[0..2] of integer=(100,524,524);
  ledy:array[0..2] of integer=(76,20,100);
begin
  setcolor(bl2); circle(ledx[n],ledy[n],8);
  setcolor(kcob); setfillstyle(1,kcob); floodfill(ledx[n],ledy[n],bl2);
  if p then setcolor(4) else setcolor(1);
  if p then setfillstyle(1,4) else setfillstyle(1,1);
  fillellipse(ledx[n],ledy[n],5,5);
end;

procedure timesetting;
begin
  if ketyeg then led(0,true) else led(0,false);
end;

procedure playersetting;
begin
  led(pl,true); led(3-pl,false);
end;

function nyom(pl:integer):real;
var
  sum:real;
  x,y:integer;
begin
  sum:=0;
  for x:=-4 to 4 do for y:=-4 to 4 do if st[x,y]=pl then sum:=sum+ny[x,y];
  nyom:=sum;
end;

function varh(pl:integer;var sx,sy:real):real;
var
  x,y,n:integer;
begin
  sx:=0; sy:=0; n:=0;
  for x:=-4 to 4 do for y:=-4 to 4 do if st[x,y]=pl then begin
    sx:=sx+c_cx[x,y];
    sy:=sy+c_cy[x,y];
    inc(n);
  end;
  sx:=sx/n; sy:=sy/n;
  varh:=(cx-sx)*(cx-sx)+(cy-sy)*(cy-sy);
end;

function darab(pl:integer):integer;
var x,y,sum:integer;
begin
  sum:=0;
  for x:=-4 to 4 do for y:=-4 to 4 do if st[x,y]=pl then inc(sum);
  darab:=sum;
end;

procedure calculate_and_step(level:integer);
var
  x2,y2,dx,dy,n:integer;
  x2b,y2b,dxb,dyb,nb:integer;
  gx2,gy2,gdx,gdy,kx2,ky2,kdx,kdy:integer;
  okstep,lehetlokni:boolean;
  auxst:stt; auxsc:sct;
  aux2st:stt; aux2sc:sct;
  egynyom,minnyom,maxnyom,sx,sy:real;
begin

  if level=0 then begin
    repeat
      auxst:=st; auxsc:=sc;
      okstep:=true;
      x2:=random(9); y2:=random(9); dx:=random(3); dy:=random(3);
      dec(x2,4); dec(y2,4); dec(dx); dec(dy);
      if (st[x2,y2]<>pl) or (dx=dy)  then okstep:=false;
      if okstep then n:=dostep(x2,y2,dx,dy);
      if n=0 then okstep:=false;
      if not okstep then begin st:=auxst; sc:=auxsc; end;
    until okstep;
    tx[step]:=x2; ty[step]:=y2; tdx[step]:=dx; tdy[step]:=dy; tn[step]:=n;
  end;

  if level=1 then begin
    minnyom:=1e6;
    fastmode:=true;
    for x2:=-4 to 4 do for y2:=-4 to 4 do if st[x2,y2]=pl then begin
      for dx:=-1 to 1 do for dy:=-1 to 1 do if dx<>dy then begin
        auxst:=st; auxsc:=sc;
        if dostep(x2,y2,dx,dy)>0 then begin
          egynyom:=nyom(pl);
          if ketyeg then timesget;
          if egynyom<minnyom then begin
            minnyom:=egynyom;
            gx2:=x2; gy2:=y2; gdx:=dx; gdy:=dy;
          end;
        end;
        st:=auxst; sc:=auxsc;
      end;
    end;
    fastmode:=false;
    n:=dostep(gx2,gy2,gdx,gdy);
    tx[step]:=gx2; ty[step]:=gy2; tdx[step]:=gdx; tdy[step]:=gdy; tn[step]:=n;
  end;

  if level=2 then begin
    minnyom:=1e6;
    fastmode:=true;
    lehetlokni:=false;
    for x2:=-4 to 4 do for y2:=-4 to 4 do if st[x2,y2]=pl then begin
      for dx:=-1 to 1 do for dy:=-1 to 1 do if dx<>dy then begin
        auxst:=st; auxsc:=sc; n:=darab(3-pl);
        if dostep(x2,y2,dx,dy)>0 then begin
          if darab(3-pl)<n then begin
            kx2:=x2; ky2:=y2; kdx:=dx; kdy:=dy; lehetlokni:=true;
          end;
          egynyom:=nyom(pl);
          if ketyeg then timesget;
          if egynyom<minnyom then begin
            minnyom:=egynyom;
            gx2:=x2; gy2:=y2; gdx:=dx; gdy:=dy;
          end;
        end;
        st:=auxst; sc:=auxsc;
      end;
    end;
    fastmode:=false;
    if lehetlokni then begin
      n:=dostep(kx2,ky2,kdx,kdy);
      tx[step]:=kx2; ty[step]:=ky2;
      tdx[step]:=kdx; tdy[step]:=kdy; tn[step]:=n;
    end
    else begin
      n:=dostep(gx2,gy2,gdx,gdy);
      tx[step]:=gx2; ty[step]:=gy2;
      tdx[step]:=gdx; tdy[step]:=gdy; tn[step]:=n;
    end;
  end;

  if level=3 then begin
    minnyom:=1e6;
    fastmode:=true;
    for x2:=-4 to 4 do for y2:=-4 to 4 do if st[x2,y2]=pl then begin
      for dx:=-1 to 1 do for dy:=-1 to 1 do if dx<>dy then begin
        auxst:=st; auxsc:=sc;
        if dostep(x2,y2,dx,dy)>0 then begin

          if ketyeg then timesget;
          pl:=3-pl;
          maxnyom:=0;
          for x2b:=-4 to 4 do for y2b:=-4 to 4 do if st[x2b,y2b]=pl then begin
            for dxb:=-1 to 1 do for dyb:=-1 to 1 do if dxb<>dyb then begin
              aux2st:=st; aux2sc:=sc;
              if dostep(x2b,y2b,dxb,dyb)>0 then begin
                egynyom:=nyom(3-pl)/nyom(pl);
                if egynyom>maxnyom then maxnyom:=egynyom;
              end;
              st:=aux2st; sc:=aux2sc;
            end;
          end;
          pl:=3-pl;

          if maxnyom<minnyom then begin
            minnyom:=maxnyom;
            gx2:=x2; gy2:=y2; gdx:=dx; gdy:=dy;
          end;
        end;
        st:=auxst; sc:=auxsc;
      end;
    end;
    fastmode:=false;
    n:=dostep(gx2,gy2,gdx,gdy);
    tx[step]:=gx2; ty[step]:=gy2; tdx[step]:=gdx; tdy[step]:=gdy; tn[step]:=n;
  end;

  if level=4 then begin
    minnyom:=1e6;
    fastmode:=true;
    lehetlokni:=false;
    for x2:=-4 to 4 do for y2:=-4 to 4 do if st[x2,y2]=pl then begin
      for dx:=-1 to 1 do for dy:=-1 to 1 do if dx<>dy then begin
        auxst:=st; auxsc:=sc; n:=darab(3-pl);
        if dostep(x2,y2,dx,dy)>0 then begin
          if darab(3-pl)<n then begin
            kx2:=x2; ky2:=y2; kdx:=dx; kdy:=dy; lehetlokni:=true;
          end
          else begin

          if ketyeg then timesget;
          pl:=3-pl;
          maxnyom:=0;
          for x2b:=-4 to 4 do for y2b:=-4 to 4 do if st[x2b,y2b]=pl then begin
            for dxb:=-1 to 1 do for dyb:=-1 to 1 do if dxb<>dyb then begin
              aux2st:=st; aux2sc:=sc;
              if dostep(x2b,y2b,dxb,dyb)>0 then begin
                egynyom:=nyom(3-pl)/nyom(pl);
                if egynyom>maxnyom then maxnyom:=egynyom;
              end;
              st:=aux2st; sc:=aux2sc;
            end;
          end;
          pl:=3-pl;

          if maxnyom<minnyom then begin
            minnyom:=maxnyom;
            gx2:=x2; gy2:=y2; gdx:=dx; gdy:=dy;
          end;

          end;
        end;
        st:=auxst; sc:=auxsc;
      end;
    end;
    fastmode:=false;
    if lehetlokni then begin
      n:=dostep(kx2,ky2,kdx,kdy);
      tx[step]:=kx2; ty[step]:=ky2;
      tdx[step]:=kdx; tdy[step]:=kdy; tn[step]:=n;
    end
    else begin
      n:=dostep(gx2,gy2,gdx,gdy);
      tx[step]:=gx2; ty[step]:=gy2; tdx[step]:=gdx; tdy[step]:=gdy; tn[step]:=n;
    end;
  end;

end;

procedure mainloop;
var
  x2,y2,dx,dy,n,butt,i,code:integer;
  gameend:boolean;
  s,name:string;
  locker:boolean;
  valt:boolean;

procedure b_new_press;
var
  i:integer; name:string; escape:boolean; auxst:stt; auxsc:sct;
begin
  auxst:=st; auxsc:=sc;
  sc[1]:=0; sc[2]:=0; out; st:=firstst; state; kijn(1,3);
  name:='PL 1'; escape:=not inputname(name);
  if escape then begin
    st:=auxst; sc:=auxsc; out; state; kijn(step,3);
  end
  else begin
    names[1]:=name; kij(name,4); kij(' ',5);
    repeat name:='PL 2' until inputname(name);
    names[2]:=name; kij(name,6); kij(' ',7);
    pl:=1; step:=1; maxstep:=1; playersetting;
    for i:=0 to 2 do begin mins[i]:=0; secs[i]:=0; stopper[i]:=' 0 00'; end;
  end;
end;
procedure b_f_press;
begin
  if step+1>maxstep then beep else begin
    x2:=tx[step]; y2:=ty[step]; dx:=tdx[step]; dy:=tdy[step];
    n:=dostep(x2,y2,dx,dy);
    inc(step); pl:=3-pl; kijn(step,3); playersetting;
  end;
end;
procedure b_b_press;
begin
  if step=1 then beep else begin
    dec(step); pl:=3-pl; kijn(step,3); playersetting; gameend:=false;
    x2:=tx[step]; y2:=ty[step]; dx:=tdx[step]; dy:=tdy[step];
    n:=tn[step];
    undostep(x2,y2,dx,dy,n);
  end;
end;
procedure b_ff_press;
begin
  if step+1>maxstep then beep else begin
    fastmode:=false;
    if locker then begin
      fastmode:=true;
    end;
    while (step<maxstep) and (m_pressed or fastmode) do begin
      x2:=tx[step]; y2:=ty[step]; dx:=tdx[step]; dy:=tdy[step];
      n:=dostep(x2,y2,dx,dy);
      inc(step); pl:=3-pl;
      if not fastmode then begin
        kijn(step,3); playersetting;
      end;
    end;
    if fastmode then begin
      kijn(step,3); playersetting; out; state;
    end;
    locker:=false; button(b_lock,0); fastmode:=false;
  end;
end;
procedure b_bb_press;
begin
  if step=1 then beep else begin
    fastmode:=false;
    if locker then begin
      fastmode:=true;
    end;
    while (step>1) and (m_pressed or fastmode) do begin
      dec(step); pl:=3-pl; gameend:=false;
      if not fastmode then begin
        kijn(step,3); playersetting;
      end;
      x2:=tx[step]; y2:=ty[step]; dx:=tdx[step]; dy:=tdy[step];
      n:=tn[step];
      undostep(x2,y2,dx,dy,n);
    end;
    if fastmode then begin
      kijn(step,3); playersetting; out; state;
    end;
    locker:=false; button(b_lock,0); fastmode:=false;
  end;
end;
procedure b_lock_press;
begin
  if locker then locker:=false else locker:=true;
  if locker then button(b_lock,1) else button(b_lock,0);
end;
procedure b_save_press;
var
  i,x,y:integer;
  escape:boolean;
begin
  repeat
    name:=' SAVE ';
    escape:=not inputname(name);
  until (not existfile(name+'.aba') and (name<>'      ')) or escape;
  if not escape then begin
    assign(fil,name+'.aba');
    rewrite(fil);
    getdate(yea,mon,day,dow); gettime(hou,min,sec,s10);
    writeln(fil,yea,' ',mon,' ',day,' ',dow);
    writeln(fil,hou,' ',min);
    for i:=1 to 2 do writeln(fil,names[i]);
    for i:=0 to 2 do writeln(fil,stopper[i]);
    writeln(fil,maxstep);
    writeln(fil,step);
    writeln(fil,pl);
    if gameend then writeln(fil,'end') else writeln(fil,'int');
    for i:=1 to maxstep do begin
      write(fil,tx[i],' ',ty[i],' ',tdx[i],' ',tdy[i],' ');
      writeln(fil,tkil[i],' ',tn[i]);
    end;
    for x:=-4 to 4 do begin
      for y:=-4 to 4 do write(fil,st[x,y],' ');
      writeln(fil);
    end;
    for i:=1 to 2 do write(fil,sc[i],' ');
    close(fil);
  end;
end;
procedure b_load_press;
var
  i,x,y:integer;
  escape:boolean;
begin
  repeat
    name:=' LOAD ';
    escape:=not inputname(name);
  until existfile(name+'.aba') or escape;
  if not escape then begin
    assign(fil,name+'.aba');
    reset(fil);
    readln(fil,yea,mon,day,dow);
    readln(fil,hou,min);
    for i:=1 to 2 do readln(fil,names[i]);
    for i:=0 to 2 do readln(fil,stopper[i]);
    readln(fil,maxstep);
    readln(fil,step);
    readln(fil,pl);
    readln(fil,s); if s='end' then gameend:=true else gameend:=false;
    for i:=1 to maxstep do begin
      read(fil,tx[i],ty[i],tdx[i],tdy[i]);
      readln(fil,tkil[i],tn[i]);
    end;
    for x:=-4 to 4 do begin
      for y:=-4 to 4 do read(fil,st[x,y]);
      readln(fil);
    end;
    for i:=1 to 2 do read(fil,sc[i]);
    close(fil);
    for i:=1 to 2 do kij(names[i],2+2*i);
    kijn(step,3);
    kij(stopper[0],2); kij(stopper[1],5); kij(stopper[2],7);
    needtime:=true;
    for i:=0 to 2 do begin
      val(copy(stopper[i],1,2),mins[i],code);
      val(copy(stopper[i],4,2),secs[i],code);
    end;
    playersetting; out; state;
  end;
end;
function b_exit_press:boolean;
var
  valt:boolean;
  butt:integer;
begin
  if buttonwas=b_exit then begin
    valt:=true;
    repeat
      m_on;
      m_getstatus(mx,my,mz);
      if ketyeg then timesget;
      butt:=buttonwas;
      if not valt and (butt=b_exit) then begin
        m_off; button(b_exit,1); m_on; valt:=true; end;
      if valt and (butt<>b_exit) then
        begin m_off; button(b_exit,0); m_on; valt:=false; end;
    until (mz=0);
  end
  else valt:=false;
  b_exit_press:=valt;
end;

begin
  gameend:=false; locker:=false;
  repeat
    if gameend or (maxstep<>step) then begin ketyeg:=false; timesetting; end;
    m_releasewait(mx,my);
    if (names[pl][1]='_') and ketyeg and (step<maxmaxstep) then begin
      calculate_and_step(ord(names[pl][2])-ord('0'));
      pl:=3-pl; playersetting; inc(step); maxstep:=step; kijn(step,3);
    end;
    if (names[pl][1]<>'_') or not ketyeg then begin
      m_on;
      repeat if ketyeg then timesget; m_getstatus(mx,my,mz); until (mz=1);
      m_off;
      butt:=buttonwas;
      if butt=0 then begin
        if ballwas(x2,y2) then begin
          if not gameend then begin
            if one_step(x2,y2) then begin
              inc(step); kijn(step,3); maxstep:=step;
              pl:=3-pl;
              playersetting;
            end
            else beep;
          end
          else beep;
        end
        else if (mx>5) and (mx<87) and (my>61) and (my<91) then begin
          needtime:=not needtime;
          if needtime then timeswrite(2) else timeswrite(0);
        end
        else if (mx>105-8) and (mx<105+8) and (my>76-8) and (my<76+8) then begin
          ketyeg:=not ketyeg; timesetting;
        end
        else beep;
      end
      else begin
        if butt<>b_lock then button(butt,1);
        case butt of
          b_new:b_new_press;
          b_f:b_f_press;
          b_b:b_b_press;
          b_ff:b_ff_press;
          b_bb:b_bb_press;
          b_lock:b_lock_press;
          b_save:b_save_press;
          b_load:b_load_press;
        end;
        if (butt<>b_lock) and (butt<>b_exit) then button(butt,0);
      end;
    end
    else begin
      if ketyeg then timesget;
      m_getstatus(mx,my,mz);
      if mz=2 then begin ketyeg:=false; timesetting; end;
    end;
    if (sc[1]=6) or (sc[2]=6) then gameend:=true
    else if step=maxmaxstep then ketyeg:=false;
  until b_exit_press;
end;

procedure layout;
var
  i,bkco,whco,hico:integer;
begin
  setrgbpalette(ega[kcob],0,0,0);
  setrgbpalette(ega[wh],0,0,0);
  setrgbpalette(ega[hi],0,0,0);
  setbkcolor(kcob);
  setpalette(bl,0);
  setpalette(bl2,0);
  setpalette(12,0);
  board;
  for i:=0 to maxbut do button(i,0);
  setcolor(bl);
  setfillstyle(bkfill,bl);
  floodfill(0,0,bl);
  state;
  settextstyle(1,horizdir,0); setusercharsize(1,3,1,3); setcolor(wh);
  settextjustify(righttext,toptext);
  outtextxy(639,465,'(c) 1992 Peter Csurgay');
  setfillstyle(1,kcob);
  bar(5,5,151,47); bar(5,61,87,91); bar(5,105,59,135);
  bar(537,5,635,39); bar(553,41,635,75);
  bar(537,85,635,119); bar(553,121,635,155);
  out;
  for i:=1 to 20 do begin
    bkco:=round(c_co_bk*i/20);
    whco:=round(c_co_wh*i/20);
    hico:=round(c_co_hi*i/20);
    setrgbpalette(ega[kcob],bkco,bkco,bkco);
    setrgbpalette(ega[wh],whco,whco,whco);
    setrgbpalette(ega[hi],hico,hico,hico);
  end;
  kij('ABALON',1);
  timeswrite(0);
  kijn(1,3);
  kij(names[1],4); kij(names[2],6);
  playersetting;
  timesetting;
end;

var i:integer;
begin
  writeln(logoline); delay(500);
  cursorsavex:=wherex; cursorsavey:=wherey;
  for i:=0 to 2000 do screensave[i]:=screen[i];
  getparameters;
  if not graphinit then errorhalt('Error: I need VGA...');
  if not m_init then errorhalt('Error: I need mouse...');
  m_off;
  initialize;
  layout;
  mainloop;
  errorhalt('');
end.
