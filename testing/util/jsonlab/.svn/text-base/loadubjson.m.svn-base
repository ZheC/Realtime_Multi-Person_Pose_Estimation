function data = loadubjson(fname,varargin)
%
% data=loadubjson(fname,opt)
%    or
% data=loadubjson(fname,'param1',value1,'param2',value2,...)
%
% parse a JSON (JavaScript Object Notation) file or string
%
% authors:Qianqian Fang (fangq<at> nmr.mgh.harvard.edu)
% created on 2013/08/01
%
% $Id$
%
% input:
%      fname: input file name, if fname contains "{}" or "[]", fname
%             will be interpreted as a UBJSON string
%      opt: a struct to store parsing options, opt can be replaced by 
%           a list of ('param',value) pairs - the param string is equivallent
%           to a field in opt. opt can have the following 
%           fields (first in [.|.] is the default)
%
%           opt.SimplifyCell [0|1]: if set to 1, loadubjson will call cell2mat
%                         for each element of the JSON data, and group 
%                         arrays based on the cell2mat rules.
%           opt.IntEndian [B|L]: specify the endianness of the integer fields
%                         in the UBJSON input data. B - Big-Endian format for 
%                         integers (as required in the UBJSON specification); 
%                         L - input integer fields are in Little-Endian order.
%
% output:
%      dat: a cell array, where {...} blocks are converted into cell arrays,
%           and [...] are converted to arrays
%
% examples:
%      obj=struct('string','value','array',[1 2 3]);
%      ubjdata=saveubjson('obj',obj);
%      dat=loadubjson(ubjdata)
%      dat=loadubjson(['examples' filesep 'example1.ubj'])
%      dat=loadubjson(['examples' filesep 'example1.ubj'],'SimplifyCell',1)
%
% license:
%     BSD or GPL version 3, see LICENSE_{BSD,GPLv3}.txt files for details 
%
% -- this function is part of JSONLab toolbox (http://iso2mesh.sf.net/cgi-bin/index.cgi?jsonlab)
%

global pos inStr len  esc index_esc len_esc isoct arraytoken fileendian systemendian

if(regexp(fname,'[\{\}\]\[]','once'))
   string=fname;
elseif(exist(fname,'file'))
   fid = fopen(fname,'rb');
   string = fread(fid,inf,'uint8=>char')';
   fclose(fid);
else
   error('input file does not exist');
end

pos = 1; len = length(string); inStr = string;
isoct=exist('OCTAVE_VERSION','builtin');
arraytoken=find(inStr=='[' | inStr==']' | inStr=='"');
jstr=regexprep(inStr,'\\\\','  ');
escquote=regexp(jstr,'\\"');
arraytoken=sort([arraytoken escquote]);

% String delimiters and escape chars identified to improve speed:
esc = find(inStr=='"' | inStr=='\' ); % comparable to: regexp(inStr, '["\\]');
index_esc = 1; len_esc = length(esc);

opt=varargin2struct(varargin{:});
fileendian=upper(jsonopt('IntEndian','B',opt));
[os,maxelem,systemendian]=computer;

jsoncount=1;
while pos <= len
    switch(next_char)
        case '{'
            data{jsoncount} = parse_object(opt);
        case '['
            data{jsoncount} = parse_array(opt);
        otherwise
            error_pos('Outer level structure must be an object or an array');
    end
    jsoncount=jsoncount+1;
end % while

jsoncount=length(data);
if(jsoncount==1 && iscell(data))
    data=data{1};
end

if(~isempty(data))
      if(isstruct(data)) % data can be a struct array
          data=jstruct2array(data);
      elseif(iscell(data))
          data=jcell2array(data);
      end
end


%%
function newdata=parse_collection(id,data,obj)

if(jsoncount>0 && exist('data','var')) 
    if(~iscell(data))
       newdata=cell(1);
       newdata{1}=data;
       data=newdata;
    end
end

%%
function newdata=jcell2array(data)
len=length(data);
newdata=data;
for i=1:len
      if(isstruct(data{i}))
          newdata{i}=jstruct2array(data{i});
      elseif(iscell(data{i}))
          newdata{i}=jcell2array(data{i});
      end
end

%%-------------------------------------------------------------------------
function newdata=jstruct2array(data)
fn=fieldnames(data);
newdata=data;
len=length(data);
for i=1:length(fn) % depth-first
    for j=1:len
        if(isstruct(getfield(data(j),fn{i})))
            newdata(j)=setfield(newdata(j),fn{i},jstruct2array(getfield(data(j),fn{i})));
        end
    end
end
if(~isempty(strmatch('x0x5F_ArrayType_',fn)) && ~isempty(strmatch('x0x5F_ArrayData_',fn)))
  newdata=cell(len,1);
  for j=1:len
    ndata=cast(data(j).x0x5F_ArrayData_,data(j).x0x5F_ArrayType_);
    iscpx=0;
    if(~isempty(strmatch('x0x5F_ArrayIsComplex_',fn)))
        if(data(j).x0x5F_ArrayIsComplex_)
           iscpx=1;
        end
    end
    if(~isempty(strmatch('x0x5F_ArrayIsSparse_',fn)))
        if(data(j).x0x5F_ArrayIsSparse_)
            if(~isempty(strmatch('x0x5F_ArraySize_',fn)))
                dim=double(data(j).x0x5F_ArraySize_);
                if(iscpx && size(ndata,2)==4-any(dim==1))
                    ndata(:,end-1)=complex(ndata(:,end-1),ndata(:,end));
                end
                if isempty(ndata)
                    % All-zeros sparse
                    ndata=sparse(dim(1),prod(dim(2:end)));
                elseif dim(1)==1
                    % Sparse row vector
                    ndata=sparse(1,ndata(:,1),ndata(:,2),dim(1),prod(dim(2:end)));
                elseif dim(2)==1
                    % Sparse column vector
                    ndata=sparse(ndata(:,1),1,ndata(:,2),dim(1),prod(dim(2:end)));
                else
                    % Generic sparse array.
                    ndata=sparse(ndata(:,1),ndata(:,2),ndata(:,3),dim(1),prod(dim(2:end)));
                end
            else
                if(iscpx && size(ndata,2)==4)
                    ndata(:,3)=complex(ndata(:,3),ndata(:,4));
                end
                ndata=sparse(ndata(:,1),ndata(:,2),ndata(:,3));
            end
        end
    elseif(~isempty(strmatch('x0x5F_ArraySize_',fn)))
        if(iscpx && size(ndata,2)==2)
             ndata=complex(ndata(:,1),ndata(:,2));
        end
        ndata=reshape(ndata(:),data(j).x0x5F_ArraySize_);
    end
    newdata{j}=ndata;
  end
  if(len==1)
      newdata=newdata{1};
  end
end

%%-------------------------------------------------------------------------
function object = parse_object(varargin)
    parse_char('{');
    object = [];
    type='';
    count=-1;
    if(next_char == '$')
        type=inStr(pos+1); % TODO
        pos=pos+2;
    end
    if(next_char == '#')
        pos=pos+1;
        count=double(parse_number());
    end
    if next_char ~= '}'
        num=0;
        while 1
            str = parseStr(varargin{:});
            if isempty(str)
                error_pos('Name of value at position %d cannot be empty');
            end
            %parse_char(':');
            val = parse_value(varargin{:});
            num=num+1;
            eval( sprintf( 'object.%s  = val;', valid_field(str) ) );
            if next_char == '}' || (count>=0 && num>=count)
                break;
            end
            %parse_char(',');
        end
    end
    if(count==-1)
        parse_char('}');
    end

%%-------------------------------------------------------------------------
function [cid,len]=elem_info(type)
id=strfind('iUIlLdD',type);
dataclass={'int8','uint8','int16','int32','int64','single','double'};
bytelen=[1,1,2,4,8,4,8];
if(id>0)
    cid=dataclass{id};
    len=bytelen(id);
else
    error_pos('unsupported type at position %d');
end
%%-------------------------------------------------------------------------


function [data adv]=parse_block(type,count,varargin)
global pos inStr isoct fileendian systemendian
[cid,len]=elem_info(type);
datastr=inStr(pos:pos+len*count-1);
if(isoct)
    newdata=int8(datastr);
else
    newdata=uint8(datastr);
end
id=strfind('iUIlLdD',type);
if(id<=5 && fileendian~=systemendian)
    newdata=swapbytes(typecast(newdata,cid));
end
data=typecast(newdata,cid);
adv=double(len*count);

%%-------------------------------------------------------------------------


function object = parse_array(varargin) % JSON array is written in row-major order
global pos inStr isoct
    parse_char('[');
    object = cell(0, 1);
    dim=[];
    type='';
    count=-1;
    if(next_char == '$')
        type=inStr(pos+1);
        pos=pos+2;
    end
    if(next_char == '#')
        pos=pos+1;
        if(next_char=='[')
            dim=parse_array(varargin{:});
            count=prod(double(dim));
        else
            count=double(parse_number());
        end
    end
    if(~isempty(type))
        if(count>=0)
            [object adv]=parse_block(type,count,varargin{:});
            if(~isempty(dim))
                object=reshape(object,dim);
            end
            pos=pos+adv;
            return;
        else
            endpos=matching_bracket(inStr,pos);
            [cid,len]=elem_info(type);
            count=(endpos-pos)/len;
            [object adv]=parse_block(type,count,varargin{:});
            pos=pos+adv;
            parse_char(']');
            return;
        end
    end
    if next_char ~= ']'
         while 1
            val = parse_value(varargin{:});
            object{end+1} = val;
            if next_char == ']'
                break;
            end
            %parse_char(',');
         end
    end
    if(jsonopt('SimplifyCell',0,varargin{:})==1)
      try
        oldobj=object;
        object=cell2mat(object')';
        if(iscell(oldobj) && isstruct(object) && numel(object)>1 && jsonopt('SimplifyCellArray',1,varargin{:})==0)
            object=oldobj;
        elseif(size(object,1)>1 && ndims(object)==2)
            object=object';
        end
      catch
      end
    end
    if(count==-1)
        parse_char(']');
    end

%%-------------------------------------------------------------------------

function parse_char(c)
    global pos inStr len
    skip_whitespace;
    if pos > len || inStr(pos) ~= c
        error_pos(sprintf('Expected %c at position %%d', c));
    else
        pos = pos + 1;
        skip_whitespace;
    end

%%-------------------------------------------------------------------------

function c = next_char
    global pos inStr len
    skip_whitespace;
    if pos > len
        c = [];
    else
        c = inStr(pos);
    end

%%-------------------------------------------------------------------------

function skip_whitespace
    global pos inStr len
    while pos <= len && isspace(inStr(pos))
        pos = pos + 1;
    end

%%-------------------------------------------------------------------------
function str = parseStr(varargin)
    global pos inStr esc index_esc len_esc
 % len, ns = length(inStr), keyboard
    type=inStr(pos);
    if type ~= 'S' && type ~= 'C' && type ~= 'H'
        error_pos('String starting with S expected at position %d');
    else
        pos = pos + 1;
    end
    if(type == 'C')
        str=inStr(pos);
        pos=pos+1;
        return;
    end
    bytelen=double(parse_number());
    if(length(inStr)>=pos+bytelen-1)
        str=inStr(pos:pos+bytelen-1);
        pos=pos+bytelen;
    else
        error_pos('End of file while expecting end of inStr');
    end

%%-------------------------------------------------------------------------

function num = parse_number(varargin)
    global pos inStr len isoct fileendian systemendian
    id=strfind('iUIlLdD',inStr(pos));
    if(isempty(id))
        error_pos('expecting a number at position %d');
    end
    type={'int8','uint8','int16','int32','int64','single','double'};
    bytelen=[1,1,2,4,8,4,8];
    datastr=inStr(pos+1:pos+bytelen(id));
    if(isoct)
        newdata=int8(datastr);
    else
        newdata=uint8(datastr);
    end
    if(id<=5 && fileendian~=systemendian)
        newdata=swapbytes(typecast(newdata,type{id}));
    end
    num=typecast(newdata,type{id});
    pos = pos + bytelen(id)+1;

%%-------------------------------------------------------------------------

function val = parse_value(varargin)
    global pos inStr len
    true = 1; false = 0;

    switch(inStr(pos))
        case {'S','C','H'}
            val = parseStr(varargin{:});
            return;
        case '['
            val = parse_array(varargin{:});
            return;
        case '{'
            val = parse_object(varargin{:});
            if isstruct(val)
                if(~isempty(strmatch('x0x5F_ArrayType_',fieldnames(val), 'exact')))
                    val=jstruct2array(val);
                end
            elseif isempty(val)
                val = struct;
            end
            return;
        case {'i','U','I','l','L','d','D'}
            val = parse_number(varargin{:});
            return;
        case 'T'
            val = true;
            pos = pos + 1;
            return;
        case 'F'
            val = false;
            pos = pos + 1;
            return;
        case {'Z','N'}
            val = [];
            pos = pos + 1;
            return;
    end
    error_pos('Value expected at position %d');
%%-------------------------------------------------------------------------

function error_pos(msg)
    global pos inStr len
    poShow = max(min([pos-15 pos-1 pos pos+20],len),1);
    if poShow(3) == poShow(2)
        poShow(3:4) = poShow(2)+[0 -1];  % display nothing after
    end
    msg = [sprintf(msg, pos) ': ' ...
    inStr(poShow(1):poShow(2)) '<error>' inStr(poShow(3):poShow(4)) ];
    error( ['JSONparser:invalidFormat: ' msg] );

%%-------------------------------------------------------------------------

function str = valid_field(str)
global isoct
% From MATLAB doc: field names must begin with a letter, which may be
% followed by any combination of letters, digits, and underscores.
% Invalid characters will be converted to underscores, and the prefix
% "x0x[Hex code]_" will be added if the first character is not a letter.
    pos=regexp(str,'^[^A-Za-z]','once');
    if(~isempty(pos))
        if(~isoct)
            str=regexprep(str,'^([^A-Za-z])','x0x${sprintf(''%X'',unicode2native($1))}_','once');
        else
            str=sprintf('x0x%X_%s',char(str(1)),str(2:end));
        end
    end
    if(isempty(regexp(str,'[^0-9A-Za-z_]', 'once' ))) return;  end
    if(~isoct)
        str=regexprep(str,'([^0-9A-Za-z_])','_0x${sprintf(''%X'',unicode2native($1))}_');
    else
        pos=regexp(str,'[^0-9A-Za-z_]');
        if(isempty(pos)) return; end
        str0=str;
        pos0=[0 pos(:)' length(str)];
        str='';
        for i=1:length(pos)
            str=[str str0(pos0(i)+1:pos(i)-1) sprintf('_0x%X_',str0(pos(i)))];
        end
        if(pos(end)~=length(str))
            str=[str str0(pos0(end-1)+1:pos0(end))];
        end
    end
    %str(~isletter(str) & ~('0' <= str & str <= '9')) = '_';

%%-------------------------------------------------------------------------
function endpos = matching_quote(str,pos)
len=length(str);
while(pos<len)
    if(str(pos)=='"')
        if(~(pos>1 && str(pos-1)=='\'))
            endpos=pos;
            return;
        end        
    end
    pos=pos+1;
end
error('unmatched quotation mark');
%%-------------------------------------------------------------------------
function [endpos e1l e1r maxlevel] = matching_bracket(str,pos)
global arraytoken
level=1;
maxlevel=level;
endpos=0;
bpos=arraytoken(arraytoken>=pos);
tokens=str(bpos);
len=length(tokens);
pos=1;
e1l=[];
e1r=[];
while(pos<=len)
    c=tokens(pos);
    if(c==']')
        level=level-1;
        if(isempty(e1r)) e1r=bpos(pos); end
        if(level==0)
            endpos=bpos(pos);
            return
        end
    end
    if(c=='[')
        if(isempty(e1l)) e1l=bpos(pos); end
        level=level+1;
        maxlevel=max(maxlevel,level);
    end
    if(c=='"')
        pos=matching_quote(tokens,pos+1);
    end
    pos=pos+1;
end
if(endpos==0) 
    error('unmatched "]"');
end

