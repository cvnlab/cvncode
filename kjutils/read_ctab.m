function ctab=read_ctab(filename)

assert(exist(filename,'file')>0);
    
fid=fopen(filename,'r');
M=textscan(fid,'%d %s %d %d %d %d %*s','commentstyle','#');
fclose(fid);

if(isempty(M))
    ctab=[];
    return;
end


labelidx=cell2mat(M(1));
labelnames=M{2};
rgb=cell2mat(M(3:5));
flag=cell2mat(M(6));

rgbval=rgb(:,1)+rgb(:,2)*(2^8) + rgb(:,3)*(2^16) + flag*(2^24);

if(all(rgbval==0))
    rgbval=labelidx;
    structid=labelidx;
else
    structid=rgbval;
end
ctab=struct('numEntries',numel(M{1}),'orig_tab',filename,'struct_names',{labelnames},'table',[rgb flag rgbval],'structureID',structid);
