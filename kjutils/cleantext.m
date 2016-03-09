function s = cleantext(str)
%s = cleantext(str)
%fix \ and _ for figure text, titles, etc..

s = regexprep(str,'\','\\\\');
s = regexprep(s,'_','\\_');
