function show( modelArray )
% SHOW displays the results of the estimation of the model (first contrast)

assert( numel(modelArray)==1 , '@model/show method only works for 1 object, not an array of objects' )

matlabbatch{1}.spm.stats.results.spmmat = {modelArray.path};
matlabbatch{1}.spm.stats.results.conspec.titlestr = '';
matlabbatch{1}.spm.stats.results.conspec.contrasts = 1;
matlabbatch{1}.spm.stats.results.conspec.threshdesc = 'FWE';
matlabbatch{1}.spm.stats.results.conspec.thresh = 0.05;
matlabbatch{1}.spm.stats.results.conspec.extent = 0;
matlabbatch{1}.spm.stats.results.conspec.conjunction = 1;
matlabbatch{1}.spm.stats.results.conspec.mask.none = 1;
matlabbatch{1}.spm.stats.results.units = 1;
matlabbatch{1}.spm.stats.results.print = false;
matlabbatch{1}.spm.stats.results.write.none = 1;

spm('defaults','fmri')
spm_jobman('run',matlabbatch)

fprintf('results from : %s \n', modelArray.path)

end % function
