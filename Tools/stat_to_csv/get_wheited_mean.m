function [Y varargout] = get_wheited_mean(fa,fcon,par)

if ~exist('par'),par ='';end

defpar.seuil = 0;

par = complet_struct(par,defpar);

seuil=par.seuil;

%at the subject level
fcon = cellstr(char(fcon));

Y = zeros(length(fa),length(seuil));

for i=1:length(fa)
    tt=zeros(1,length(seuil));
    %     [FAimg,dimes,vox]=read_avw(fa{i});
    %     for j=1:length(fcon)
    %         [Conimg,dimes,vox]=read_avw(fcon{j});
    %         Y(i,j) = sum(FAimg(Conimg>seuil).*Conimg(Conimg>seuil))./sum(Conimg(Conimg>seuil));
    %     end
    
    [FAimg,dimes,vox]=read_avw(fa{i});
    [Conimg,dimes,vox]=read_avw(fcon{i});

    %remove NaN
    FAimg(isnan(FAimg))=0;
    
    for kk =1:length(seuil)
        tt(kk) = sum(FAimg(Conimg>seuil(kk)).*Conimg(Conimg>seuil(kk)))./sum(Conimg(Conimg>seuil(kk)));
    end
    Y(i,:) = tt;
    if nargout>1
        %fprintf('comput std\n')
        Ystd(i) = std(FAimg(Conimg>seuil(1)));
    end
    if nargout>2
        %fprintf('comput std\n')
        aa = (Conimg>seuil(1));
        Vol(i) = sum(aa(:));
    end
end

if nargout>1
    varargout{1} = Ystd;
end

if nargout > 2
    varargout{2} = Vol;
end


