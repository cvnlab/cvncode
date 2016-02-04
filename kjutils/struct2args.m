function args = struct2args(optstruct)
if(numel(optstruct) > 1)
    args = {};
    return;
end

args = [fieldnames(optstruct) struct2cell(optstruct)];
args = reshape(args.',1,[]);
