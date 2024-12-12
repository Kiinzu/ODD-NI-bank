# Odd Ni Bank

Odd Ni is an "Odd" bank, when other banks want to preserve as much money and basically "rob" their customer, `OddNi` has a different vision. They want to give their customer as much money as possible in return of using their services. The feature are including Loan, Saving and Lock to Earn models. `OddNi Bank` runs with the believe of "member"-like programs.

## To Run
1. git clone this repository
2. run `forge build`
```
forge build
```
3. run `forge test` 
```
forge test
```

## Coverage

```bash
$ forge coverage                                                                                                                                           1 ↵
[⠒] Compiling...
[⠒] Compiling 26 files with 0.8.28
[⠢] Solc 0.8.28 finished in 1.92s
Compiler run successful!
Analysing contracts...
Running tests...
| File                 | % Lines        | % Statements   | % Branches     | % Funcs       |
|----------------------|----------------|----------------|----------------|---------------|
| src/OddNiBank.sol    | 22.86% (8/35)  | 18.42% (7/38)  | 13.64% (3/22)  | 71.43% (5/7)  |
| src/OddNiBenefit.sol | 61.11% (11/18) | 54.55% (12/22) | 41.67% (10/24) | 66.67% (2/3)  |
| Total                | 35.85% (19/53) | 31.67% (19/60) | 28.26% (13/46) | 70.00% (7/10) |
```

## Known Issues
**DISCLAIMER**
This is just a joke, don't take it seriously.

1. `OddNiBenefit.sol::memberFreebie()` is A FREE GIVEAWAY, it's not an error on the calculation of `2 * Current Savings`!
2. All `Gas Optimization Issue` fall under the `Informational` risk (The Bank is rich)