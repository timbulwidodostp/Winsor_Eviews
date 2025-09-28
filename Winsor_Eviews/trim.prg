!debug = 0
logmode +addin
if !debug = 1 then
	logmode +all
endif

%type = @getthistype
if %type="NONE" then
	seterr "No object found, please open your GROUP object"
	stop
endif
	
%q1 = "0.05"
%q2 = "0.95"
%outvars =  "_trm"
!trim=1
!dogui = 1
	
'process arguments
if @len(%args) > 0 then
	%outvars = @wmid(%args,2)	 
	if @len(%outvars)>0 then
		!dogui = 0	 			
	endif
endif

if @len(@option(1)) > 0 then
	%temp = @equaloption("q1")
	if @len(%temp) > 0 then
		%q1 = %temp
	endif	
	%temp = @equaloption("q2")
	if @len(%temp)>0 then
		%q2 = %temp
	endif	
	!trim = @hasoption("wins") + 1		
endif

'GUI------------------------------------------------------
%method = """Trimming"" ""Winsorising"""
if !dogui = 1 then
	!result = @uidialog("caption", "Transforming extreme values", _
	"list",!trim,"Techniques", %method, _
	"edit",%q1,"q% lowest observations", _
	"edit",%q2,"q% highest observations", _
	"edit", %outvars, "List of output series names")
	if !result=-1 then
		stop
	endif
endif

if {%q1}<=0 or {%q2}<=0 then
	seterr "Invalid percentile. Min/Max should be between 0 and 1."
endif

if {%q1}>1 then
	%q1 = @str({%q1}/100)
endif
if {%q2}>1 then
	%q2 = @str({%q2}/100)
endif
		
if %type="SERIES" then
	%vars = _this.@name + %outvars
	series {%vars}	
	call trim({%vars}, _this, %q1, %q2, !trim)
	show {%vars}
endif

if %type="GROUP" then
	for !i=1 to @columns(_this)
		%var = _this.@seriesname(!i) + %outvars
		series {%var}	
		call trim({%var}, _this(!i), %q1, %q2, !trim)	
		%vars = %vars + " " + %var
	next
	%newgrp = _this.@name + %outvars
	group {%newgrp} {%vars}
	show {%newgrp}
endif

subroutine local trim(series out, series in, string %q1, string %q2, scalar !trim)
	!U	=	@quantile(in,%q2)	
	!L	=	@quantile(in,%q1)
	if !trim=1 then	'TRMMING
		out = @recode(in<=!L or in>=!U,na,in)
	endif
	if !trim=2 then	'WINSORISING
		out = @recode(in<=!L,!L,in)
		out = @recode(in>=!U,!U,out)
	endif
endsub
