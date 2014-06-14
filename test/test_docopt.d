import std.stdio;
import std.string;
import std.regex;
import std.algorithm;
import std.file;
import std.path;
import std.json;

import docopt;

string prettyArgValue(docopt.ArgValue[string] dict) {
    string ret = "{";
    bool first = true;
    foreach(key, val; dict) {
        if (first)
            first = false;
        else
            ret ~= ",";

        ret ~= format("\"%s\"", key);
        ret ~= ":";
        if (val.isBool) {
            ret ~= val.toString;
        } else if (val.isInt) {
            ret ~= val.toString;
        } else if (val.isNull) {
            ret ~= "null";
        } else if (val.isList) {
            ret ~= "[";
            bool firstList = true;
            foreach(str; val.asList) {
                if (firstList)
                    firstList = false;
                else
                    ret ~= ",";
                ret ~= format("\"%s\"", str);
            }
            ret ~= "]";
        } else {
            ret ~= format("\"%s\"", val.toString);
        }
    }
    ret ~= "}";
    return ret;
}

class DocoptTestItem {
    private string _doc;
    private uint _index;
    private string _prog;
    private string[] _argv;
    private JSONValue _expect;
    this(string doc, uint index, string prog, string[] argv, JSONValue expect) {
        _doc = doc;
        _index = index;
        _prog = prog;
        _argv = argv;
        _expect = expect;
    }

    bool runTest() {
        string result;
        try {
           docopt.ArgValue[string] temp = docopt.parse(_doc, _argv);
           result = prettyArgValue(temp);
        } catch (DocoptArgumentError e) {
            result = "\"user-error\""; // parseJSON("user-error");
            return (result == _expect.toString);
        } catch (Exception e) {
            writeln(e);
            return false;
        }
        JSONValue _result = parseJSON(result);

        if (_expect.toPrettyString == _result.toPrettyString) {
            return true;
        } else {
            writeln(_index);
            writeln(_doc);
            writeln(format("expect: %s\nresult: %s", 
                           _expect.toPrettyString, _result.toPrettyString));
            return false;
        }
    }
}

DocoptTestItem[] splitTestCases(string raw) {
    auto pat = regex("#.*$", "m");
    auto res = replaceAll(raw, pat, "");
    if (startsWith(raw, "\"\"\"")) {
        raw = raw[3..$];
    }
    auto fixtures = split(raw, "r\"\"\"");

    DocoptTestItem[] testcases;
    foreach(uint i, fixture; fixtures[1..$]) {
        auto parts = fixture.split("\"\"\"");
        if (parts.length == 2) {
            auto doc = parts[0];
            foreach(testcase; parts[1].split('$')[1..$]) {
                auto argv_parts = strip(testcase).split("\n");
                auto expect = parseJSON(join(argv_parts[1..$], "\n"));
                auto prog_parts = argv_parts[0].split(" ");
                auto prog = prog_parts[0];
                string[] argv = [];
                if (prog_parts.length > 1) {
                    argv = prog_parts[1..$];
                } 
                testcases ~= new DocoptTestItem(doc, i, prog, argv, expect);
            }
        }
    }
    return testcases;
}

int main(string[] args) {

    if (args.length < 2) {
        writeln("usage: test_docopt <testfile>");
        return 1;
    }
    auto raw = readText(args[1]);

    auto testcases = splitTestCases(raw);
    uint passed[];
    foreach(uint i, test; testcases) {
        if (test.runTest()) {
            passed ~= i;
        }
    }
    writeln(format("%d passed of %d run : %.1f%%", 
                   passed.length, testcases.length,
                   100.0*cast(float)passed.length/cast(float)testcases.length));

    return 0;
}