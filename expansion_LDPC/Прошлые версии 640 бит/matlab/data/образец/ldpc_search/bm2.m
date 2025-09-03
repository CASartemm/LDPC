function p = bm2(s)
% BM2 - Berlekamp-Massey Algorithm for LFSR Synthesis
%  p = bm2(s) gives the LFSR feedback polynomial coefficients
%      p in binary vector form for the given binary sequence s 
%      using BM LFSR synthesis algorithm.
%
%  p : 1x(L+1) binary vector, the coefficients of the LFSR,
%              where L is the number of delay elements in the LFSR
%  s : 1xn     binary vector, the output bits from an LFSR,
%              where n >= 2*L for correct estimation of the LFSR
%              coeffcients
% 
% Usage: Refer to bm2_test.m script distributed together with this file.
% References:
%  [1] James L. Massey, "Shift-register synthesis and BCH decoding",
%      IEEE Trans. Informa. Theory, vol. 15, no. 1, pp. 122-127, Jan.1969
%
% v1.0 by Byoungjo CHOI, bjc97r@inu.ac.kr at 10 Dec. 2019
% v1.1 by Byoungjo CHOI, bjc97r@inu.ac.kr at 11 Dec. 2019
%      error fixed for generating d in step 2)
% Verified with MATLAB R2019b
%
%% Step 1) Initialization
c = 1;  % the current estimate of the LFSR poly in decimal notation
B = 1;  % the previous estimate of the LFSR poly before L change
x = 1;  % the accumulated delay order to B for the next L change
L = 0;  % the current estimate of the LFSR order
N = 0;  % the currently considered index of the sequence s
n = length(s);
%% Loop
for k=1:n
    % Step 2) Discrepancy bit calculation
    s1 = s(N+1:-1:N-L+1);
    if L == 0
        d = s1;
    else
        cb = dec2bin(c,L+1)-'0';
        c1 = cb(end:-1:1);
        d  = mod( c1 * s1', 2 );
    end
    
    % Step 3) No discrepancy to the current estimate
    if d == 0
        x = x + 1;
    % Step 4) No L change, but update LFSR poly
    elseif N < 2*L
        c = bitxor( c, 2^x*B);
        x = x + 1;
    % Step 5) L change and update LFSR poly
    else
        T = c;
        c = bitxor( c, 2^x*B);
        L = N + 1 -L;
        B = T;
        x = 1;
    end
    % Step 6) Update N
    N = N + 1;
end
cb = dec2bin(c,L)-'0';
p  = [1 cb(L:-1:1)];
end