function m = wildcardmatch(str,expr)

m=~cellfun(@isempty,regexp(str,['^' regexptranslate('wildcard',expr) '$']));
