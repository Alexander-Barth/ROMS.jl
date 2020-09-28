function vii = interp3_var(depth,H_rho,v,z)


xi_rho = size(z,1);
eta_rho = size(z,2);
s_rho = size(z,3);

kmax = size(v,3);
vi = zeros([xi_rho eta_rho kmax]);


for k=1:kmax
  tmp = v(:,:,k);
  vi(:,:,k) = reshape(H_rho * tmp(:),xi_rho,eta_rho);
end

if kmax == 1
  vii = vi;
else
  if 1
  vii = zeros(xi_rho,eta_rho,s_rho);
  
  for j=1:eta_rho
    for i=1:xi_rho
      vii(i,j,:) = interp1(depth,squeeze(vi(i,j,:)),squeeze(z(i,j,:)));
    end
  end      
  else
    depth = repmat(reshape(depth,[1 1 kmax]),[xi_rho eta_rho 1]);
    vii = vinterp(depth,vi,z);
  end
end
