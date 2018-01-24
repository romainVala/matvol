function review( modelArray )
% REVIEW displays the model

assert( numel(modelArray)==1 , '@model/review method only works for 1 object, not an array of objects' )

matlabbatch{1}.spm.stats.review.spmmat = {modelArray.path};
matlabbatch{1}.spm.stats.review.display.matrix = 1;
matlabbatch{1}.spm.stats.review.print = false;

spm('defaults','fmri')
spm_jobman('run',matlabbatch)

fprintf('reviewing : %s \n', modelArray.path)

end % function
