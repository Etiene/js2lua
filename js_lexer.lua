--[[
 Lexer for Javascript source code.
 
 Author: Etiene Dalcol, Eric Mourre and Gurvan Le Bleis

 Based on C lexer by Peter Odding.
]]

local lxsh = require 'lxsh'
local lpeg = require 'lpeg'
local P = lpeg.P
local R = lpeg.R
local S = lpeg.S

-- Create a lexer definition context.
local context = lxsh.lexers.new 'js'

-- The following LPeg patterns are used as building blocks.
local U, L = R'AZ', R'az' -- uppercase, lowercase
local O, D = R'07', R'09' -- octal, decimal
local X = D + R'AF' + R'af' -- hexadecimal
local W = U + L -- case insensitive letter
local A = W + D + '_' -- identifier
local B = -A -- word boundary
local endline = S'\r\n\f' -- end of line character
local newline = '\r\n' + endline -- newline sequence
local escape = '\\' * ( newline -- escape sequence
                      + S'\\"\'?abfnrtv'
                      + (#O * O^-3)
                      + ('x' * #X * X^-2))

context:define('keyword', context:keywords [[
  break do instanceof typeof case new catch finally return void continue for switch while debugger function this with default throw delete in try
]])

context:define('var','var')
context:define('if','if')
context:define('else','else')

-- Pattern definitions start here.
context:define('whitespace' , S'\r\n\f\t\v '^1)
context:define('identifier', (W + '_') * A^0)
context:define('preprocessor', '#' * (1 - S'\r\n\f\\' + '\\' * (newline + 1))^0 * newline^-1)

-- Character and string literals.
context:define('character', "'" * ((1 - S"\\\r\n\f'") + escape) * "'")
context:define('string', '"' * ((1 - S'\\\r\n\f"') + escape)^0 * '"')

-- Comments.
local slc = '//' * (1 - endline)^0 * newline^-1
local mlc = '/*' * (1 - P'*/')^0 * '*/'
context:define('comment', slc + mlc)

-- Numbers (matched before operators because .1 is a number).
local int = (('0' * ((S'xX' * X^1) + O^1)) + D^1) * S'lL'^-2
local flt = ((D^1 * '.' * D^0
            + D^0 * '.' * D^1
            + D^1 * 'e' * D^1) * S'fF'^-1)
            + D^1 * S'fF'
context:define('number', flt + int)

-- Operators (matched after comments because of conflict with slash/division).
context:define('operator', P'>>=' + '<<=' + '--' + '>>' + '>=' + '/=' + '=='+ '===' + '<='
    + '+=' + '<<' + '*=' + '++' + '&&' + '|=' + '||' + '!=' + '&=' + '-='
    + '^=' + '%=' + '->' + S',*%+&-~/^]|.[>!?:<')

context:define('equal','=')
context:define('addassign',"+=")
context:define('subtractassign', "-=")
context:define('multiplyassign',"*=")
context:define('moduloassign', "%=")
context:define('shiftleftassign', "<<=")
context:define('shiftrightassign', ">>=")
context:define('semicolon',';')
context:define('leftpar','(')
context:define('rightpar',')')
context:define('leftcurly','{')
context:define('rightcurly','}')


-- Define an `error' token kind that consumes one character and enables
-- the lexer to resume as a last resort for dealing with unknown input.
context:define('error', 1)

return context:compile()

-- vim: ts=2 sw=2 et