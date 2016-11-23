function prefix = common_prefix(str)

if(ischar(str) && min(size(str))==1)
    prefix = str;
    return;
end

if(numel(str)==1)
    prefix = str{1};
    return;
end

str = str(:);

maxlen = max(cellfun(@numel,str));
strfmt = ['%-' num2str(maxlen) 's'] ;

padded_str = cellfun(@(x)(sprintf(strfmt,x)),str,'uniformoutput',false);
eq_str = cell2mat(cellfun(@(x)(x==padded_str{1}),padded_str,'uniformoutput',false));

v = min(find(~all(eq_str,1)));

prefix = strtrim(padded_str{1}(1:v-1));
