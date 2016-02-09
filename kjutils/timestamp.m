function s= timestamp(format)
if(nargin < 1)
    format = 'YYYYmmdd-HHMMSSFFF';
end
s = datestr(now,format);
