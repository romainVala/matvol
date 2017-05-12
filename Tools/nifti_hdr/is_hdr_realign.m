function [isalign delta delta_legend] = is_hdr_realign(v)
%function [isalign delta delta_legend] = hdr_restore_original_orientation(v)

if ~iscell(v)
    v={v};
end

for k=1:length(v)
    h=spm_vol(v{k});
    
    if strcmp(h.private.mat_intent,'Scanner')
        isalign(k)=0;
    else
        isalign(k)=1;
    end
    
    B=spm_imatrix(h.private.mat);
    A=spm_imatrix(h.private.mat0);
    
    delta(k,:) = B-A;
end

delta_legend = {
' P(1)  - x translation'
' P(2)  - y translation'
' P(3)  - z translation'
' P(4)  - x rotation about - {pitch} (radians)'
' P(5)  - y rotation about - {roll}  (radians)'
' P(6)  - z rotation about - {yaw}   (radians)'
' P(7)  - x scaling'
' P(8)  - y scaling'
' P(9)  - z scaling'
' P(10) - x affine'
' P(11) - y affine'
' P(12) - z affine'
};

delta_legend=char(delta_legend);

delta;
suj_max_mvt=max(abs(delta));

% for k=1:6
%     is(k) = find(abs(delta(:,k))==suj_max_mvt(k));
%     fprintf('\nSuj %d  %s\n%3f\t%3f\t%3f\t%3f\t%3f\t%3f',is(k),v{is(k)},delta(is(k),1),delta(is(k),2),delta(is(k),3),delta(is(k),4),delta(is(k),5),delta(is(k),6));
% end

