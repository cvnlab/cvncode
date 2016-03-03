
% subfunction: decode Siemens CSA image and series header
% From EJA at CMRR
function csa = dicom_parse_csa(csa)
b = csa';
if ~strcmp(char(b(1:4)), 'SV10'), return; end % no op if not SV10
chDat = 'AE AS CS DA DT LO LT PN SH ST TM UI UN UT';
i = 8; % 'SV10' 4 3 2 1
try %#ok in case of error, we return the original uint8
    nField = typecast(b(i+(1:4)), 'uint32'); i=i+8;
    for j = 1:nField
        if(j>=98)
            a=4;
        end
        i=i+68; % name(64) and vm(4)
        if(i+2>numel(b))
            continue;
        end
        vr = char(b(i+(1:2))); i=i+8; % vr(4), syngodt(4)
        n = typecast(b(i+(1:4)), 'int32'); i=i+8;
        if n<1, continue; end % skip name decoding, faster
        ind = find(b(i-84+(1:64))==0, 1) - 1;
        name = char(b(i-84+(1:ind)));
        % fprintf('%s %3g %s\n', vr, n, name);

        dat = [];
        for k = 1:n % n is often 6, but often only the first contains value
            len = typecast(b(i+(1:4)), 'int32'); i=i+16;
            if len<1, i = i+double(n-k)*16; break; end % rest are empty too
            foo = char(b(i+(1:len)));
            i = i + ceil(double(len)/4)*4; % multiple 4-byte
            if isempty(strfind(chDat, vr))
                dat(end+1,1) = str2double(foo); %#ok numeric to double
            else
                dat = deblank(foo);
                i = i+double(n-1)*16;
                break; % char parameters always have 1 item only
            end
        end
        if ~isempty(dat), rst.(name) = dat; end
    end
    csa = rst;
catch err
    err
    %j
    %rst
    csa = rst;

end

end