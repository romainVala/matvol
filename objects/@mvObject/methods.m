function methods( self )
%METHODS prints the methods of the object

class_name = class( self );
class_dir  = fileparts( which( class_name ) );
class_meth = dir(class_dir);
class_meth = class_meth(3:end); % remoce . and ..
class_meth = {class_meth.name};
class_meth = regexprep(class_meth,'\.m','');

sc_names   = superclasses(class_name);
sc_dir     = fileparts( which( sc_names{1} ) );
sc_meth    = dir(sc_dir);
sc_meth    = sc_meth(3:end); % remoce . and ..
sc_meth    = {sc_meth.name};
sc_meth    = regexprep(sc_meth,'\.m','');

fprintf('----- \n')
fprintf('Class %s methods are : \n', upper(class_name))
fprintf('%s \n', class_meth{:})

fprintf('---------- \n')
fprintf('Superclass %s methods are : \n', upper(sc_names{1}))
fprintf('%s \n', sc_meth{:})

end % functon
