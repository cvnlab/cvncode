function [rgbimg, alphaimg] = drawroinames(roiimg,rgbimg,Lookup,roivals,roinames,textargs)
%function rgbimg = drawroinames(img,rgbimg,roivals,roinames,imgmask,textargs)
%
% Draw roi names on top of spherelookup maps
%
%Inputs
% roiimg:     MxN ROI map returned from cvnlookupimages
% rgbimg:     MxNx3 RGB image, returned from cvnlookupimages, on which text should be drawn
% Lookup:     Lookup struct (or {L,R} cell array) returned from cvnlookupimages
% roivals:    Rx1 vector containing the 
% roinames:   Rx1 cell array with a name for each ROI
% textargs:   A cell array with arguments to control text appearance
%               (see text function)
%               Default = white on black background, size 12 font
%
%Outputs
% rgbimg:     MxNx3 RGB image with names added
%
%Examples:
%[~,roinames,~]=cvnroimask(subject,'lh','Kastner*',[],surfsuffix);
%roinames=regexprep(roinames,'@.+','');
% [img,Lookup,rgbimg]=cvnlookupimages(subject,valstruct,hemis,viewpt,...);
% rgbimg2 = drawroinames(img,rgbimg,Lookup,1:numel(roinames),roinames);

if(isstruct(Lookup))
    Lookup={Lookup};
end

if(~exist('textargs','var') || isempty(textargs))
    textargs={};
end

if(isempty(rgbimg))
    rgbimg=zeros([size(roiimg) 3]);
end

textargs0={'color','w','backgroundcolor','k',...
            'verticalalignment','middle','horizontalalignment','center','fontsize',12};

        
textbgalpha=.5;
if(any(strcmpi(textargs,'alpha')))
    aidx=find(strcmpi(textargs,'alpha'),1,'last');
    textbgalpha=min(1,max(0,textargs{aidx+1}));
    textargs=textargs(setdiff(1:numel(textargs),[aidx aidx+1]));
end

        
xoffset=0;
imgout={};
alphaimg={};
for i = 1:numel(Lookup)
    roixy={};
    roistr={};
    imgmask=false(size(roiimg));
    imgmask(:,xoffset+(1:Lookup{i}.imgsize(2)))=true;
    
    for r = 1:numel(roivals)
        m= roiimg==roivals(r) & imgmask;
        if(~any(m(:)))
            continue;
        end
        md=bwdist(~m);
        [~,mi]=max(md(:));
        [cy,cx]=ind2sub(size(md),mi);
        roixy{end+1}=[cx cy];
        roistr{end+1}=roinames{r};
    end

    roixy=cat(1,roixy{:});

    txtimg=addtext2img(nan(size(rgbimg)),{roixy(:,1),roixy(:,2),roistr,textargs0{:},textargs{:}},1);

    txtbg=isnan(txtimg);
    txtrect=~txtbg & repmat(max(txtimg,[],3)<=0,[1 1 3]);
    txtimg(txtbg)=0;
    txtalpha=min(1,~txtbg*textbgalpha + (~txtbg & ~txtrect));
    txtalpha(repmat(~imgmask,[1 1 3]))=0;
    txtimg(repmat(~imgmask,[1 1 3]))=0;
    
    imgout{i}=txtimg;
    alphaimg{i}=txtalpha;
    
    xoffset=xoffset+Lookup{i}.imgsize(2);
end

imgout=max(cat(4,imgout{:}),[],4);
alphaimg=max(cat(4,alphaimg{:}),[],4);
rgbimg=rgbimg.*(1-alphaimg) + imgout.*alphaimg;

alphaimg=alphaimg(:,:,1);
