function parsave(filename,valstruct,varargin)
save(filename,'-struct','valstruct',varargin{:});

% function parsave(varargin)
% 
% args={};
% v=struct();
% 
% filename=varargin{1};
% 
% i=2;
% while(i<=numel(varargin))
%     if(isempty(inputname(i)))
%         if(isequal(varargin{i},'-struct'))
%             v=varargin{i+1};
%             i=i+2;
%             continue;
%         else
%             args{end+1}=varargin{i};
%         end
%     else
%         v.(inputname(i))=varargin{i};
%     end
%     i=i+1;
% end
% 
% save(filename,'-struct','v',args{:});
