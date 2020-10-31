function [sys,x0,str,ts] =swiplAEBLogicInterface(t,x,u,flag,jarFile,plFile,nIn,plQuery,nOut,ClauseResult)

switch flag
    % Initialize the states, sample times, and state ordering strings.
    case 0
        [sys,x0,str,ts]=mdlInitializeSizes(jarFile,plFile,nIn,nOut,plQuery,ClauseResult);
        % Return the outputs of the S-function block.
    case 3
        sys=mdlOutputs(t,x,u,plFile,plQuery,nIn,nOut,ClauseResult);
    case 9
        sys = [];
        % Terminate
    case { 1, 2, 4}
        sys=[];
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Unexpected flags (error handling)%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Return an error message for unhandled flag values.
    otherwise
        error(['Unhandled flag = ',num2str(flag)]);
        
end

%
%=============================================================================
% mdlInitializeSizes
% Return the sizes, initial conditions, and sample times for the S-function.
%=============================================================================
%
function [sys,x0,str,ts] = mdlInitializeSizes(jarFile,plFile,nIn,nOut,plQuery,ClauseResult)

sizes = simsizes;
sizes.NumContStates  = 0;
sizes.NumDiscStates  = 0;

if ClauseResult == 0
    sizes.NumOutputs = nOut;
else
    sizes.NumOutputs = nOut+1;
end
sizes.NumInputs = nIn;


sizes.DirFeedthrough = 1;   % has direct feedthrough
sizes.NumSampleTimes = 1;

sys = simsizes(sizes);
str = [];
x0  = [];
ts  = [-1 0];   % inherited sample time

plQueryAux = plQuery;
k=strfind(lower(plQueryAux),'u(');
for i=1:length(k)
    k1 = strfind(lower(plQueryAux),'u(');
    k2 = strfind(plQueryAux(k1(1)+2:length(plQueryAux)),')');
    v = plQueryAux(k1(1)+2:k1(1)+k2(1));
    if (str2double(v) > nIn)
        error(['Error in the Prolog Query: The port u(' v ') exceeds the maximum size of the input port.']);
    end
    plQueryAux = plQueryAux(k1(1)+k2(1)+1:length(plQueryAux));
end

plQueryAux = plQuery;
k=strfind(lower(plQueryAux),'y(');
for i=1:length(k)
    k1 = strfind(lower(plQueryAux),'y(');
    k2 = strfind(plQueryAux(k1(1)+2:length(plQueryAux)),')');
    v = plQueryAux(k1(1)+2:k1(1)+k2(1));
    if (str2double(v) > nOut)
        error(['Error in the Prolog Query: The port y(' v ') exceeds the maximum size of the output port.']);
    end
    plQueryAux = plQueryAux(k1(1)+k2(1)+1:length(plQueryAux));
end

plQueryAux = plQuery;
for i=1:max(nIn,nOut)
    k=strfind(lower(plQueryAux),['(' num2str(i) ')']);
    for j=1:length(k)
        if (plQueryAux(k(j)-1) ~= 'u' && plQueryAux(k(j)-1) ~= 'y')
            k1 = strfind(lower(plQueryAux(k(j)+1:length(plQueryAux))),')');
            error(['Error in the Prolog Query: Erro in the ' plQueryAux(k(j)-1) '(' num2str(plQueryAux(k(j)+1:k(j)+1+k1(1)-2))  ') port. Use ''u'' as the input variable name and ''y'' as the output variable name']);
        end
    end
end

if isempty(cell2mat(strfind(lower(javaclasspath),'jpl.jar')))
    javaaddpath(jarFile);
end

x=org.jpl7.Query(['consult(''' plFile ''').']);
x.hasSolution;

%
%=============================================================================
% mdlOutputs
% Return the output vector for the S-function
%=============================================================================
%
function sys = mdlOutputs(t,x,u,plFile,plQuery,nIn,nOut,ClauseResult)

for i=1:nIn
    k1=strfind(lower(plQuery),['u(' num2str(i) ')']);
    for j=1:length(k1)
        k=strfind(lower(plQuery),['u(' num2str(i) ')']);
        plQuery = [plQuery(1:k(1)-1) num2str(eval(['u(' num2str(i) ')'])) plQuery(k(1)+2+length(num2str(i))+1:length(plQuery))];
    end
end


for i=1:nOut
    k=strfind(lower(plQuery),['y(' num2str(i) ')']);
    plQuery =[plQuery(1:k-1) [upper(plQuery(k)) num2str(i)] plQuery(k+2+length(num2str(i))+1:length(plQuery))];
end

x = org.jpl7.Query(plQuery);

if (ClauseResult == 0)
    m=0;
else
    m=1;
    sys(m) = double(x.hasSolution);
    
end

if ~isempty(x.oneSolution)
    v=x.oneSolution.values.toArray;
    b=x.oneSolution.keySet.toArray;
    for k=1:length(x.oneSolution.values.toArray)
        c = b(k);
        sys(str2num(c(2:length(c)))+m) = v(k).doubleValue;
    end
else
    for k=1+m:nOut+m
        sys(k) = 0;
    end
end