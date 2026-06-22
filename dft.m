function f = dft(h, g)
	K = size(h);
	L = size(g);
	%N = 2*L-1;
    %N=min(L+K-1, 2*L-1);
	f = zeros(K+L);
	%v = colonvec(N-L+1, N);
	%f(v{:}) = g;
% 	M = 0;
	%M = mod(N, 2); % Perform the FFTs with even-length data (saves roughly 10 % of computation time)
% 	tic();
	f = ifftn((fftn(h, K+L) .* fftn(g, K+L)),K+L);
	f = (f(1:K(1)+L(1)-1,1:K(2)+L(2)-1));
% 	toc();
%	v = colonvec(1, N-max(K-L, 0));
%	f = f(v{:});
end