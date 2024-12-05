#include <fstream>
#include <iostream>
#include <ostream>
#include <vector>
#include <string>

struct Vector2 {
    int x;
    int y;

    Vector2 operator*(const int s) const {
        return Vector2{
            .x = x * s,
            .y = y * s,
        };
    }

    Vector2 operator+(const Vector2 &v2) const {
        return Vector2{
            .x = x + v2.x,
            .y = y + v2.y,
        };
    }
};

inline Vector2 operator*(const int s, const Vector2 &v) {
    return v * s;
}

std::ostream &operator<<(std::ostream &os, const Vector2 &v) { 
    return os << "Vector2{ .x=" << v.x << ", .y=" << v.y << " }";
}


std::vector<std::string> linesFromFile(std::string filePath) {
    std::vector<std::string> lines;
    std::ifstream file(filePath);

    if (!file.is_open()) {
        std::cerr << "Error: Could not open file " << filePath << std::endl;
        return lines;
    }

    std::string line;
    while (std::getline(file, line)) {
        lines.push_back(line);
    }

    file.close();
    return lines;
}

char getCharacterAtPosition(const std::vector<std::string>& lines, const Vector2 &position) {
    return lines[position.y][position.x];
}

bool checkXmasDirection(std::vector<std::string>& lines, const Vector2 &position, const Vector2 &direction) {
    // check if it is even inside the boundries
    int maxX = lines[0].length();
    int maxY = lines.size();
    auto maxPosition = position + direction * 3;

    if (maxPosition.x < 0 || maxPosition.y < 0 || maxPosition.x >= maxX || maxPosition.y >= maxY) {
        return false;
    }
    
    const std::string expected = "XMAS";
    
    for (int i = 0; i < 4; i++) {
        const auto c = getCharacterAtPosition(lines, position + direction * i);
        if (c != expected[i]) {
            return false;
        }
    }

    return true;
}

const Vector2 directions[8] = {
    { .x = -1, .y = -1 },
    { .x = -1, .y = 0 },
    { .x = -1, .y = 1 },
    { .x = 0, .y = -1 },
    { .x = 0, .y = 1 },
    { .x = 1, .y = -1 },
    { .x = 1, .y = 0 },
    { .x = 1, .y = 1 },
};

int isXmas(std::vector<std::string>& lines, Vector2 position) {
    int xmasCount = 0;
    
    for (auto direction : directions) {
        if (checkXmasDirection(lines, position, direction)) {
            xmasCount++;
        }
    }

    return xmasCount;
}

int isCrossMas(std::vector<std::string>& lines, Vector2 position) {
    // check if it is even inside the boundries
    int maxX = lines[0].length();
    int maxY = lines.size();

    if (position.x < 1 || position.y < 1 || position.x >= maxX - 1 || position.y >= maxY - 1) {
        return 0;
    }

    if (getCharacterAtPosition(lines, position) != 'A') {
        return 0;
    }

    auto direction = Vector2 { .x=-1, .y=1 };
    std::string s = "";
    s += getCharacterAtPosition(lines, position + direction);
    s += getCharacterAtPosition(lines, position + direction * -1);
    if (s != "MS" && s != "SM") {
        return 0;
    }

    
    direction = Vector2 { .x=1, .y=1 };
    s = "";
    s += getCharacterAtPosition(lines, position + direction);
    s += getCharacterAtPosition(lines, position + direction * -1);

    if (s != "MS" && s != "SM") {
        return 0;
    }

    return 1;
}

int part1(std::vector<std::string> lines) {
    int totalXmas = 0;
    for ( int y = 0; y < lines.size(); y++) {
        for (int x = 0; x < lines[0].length(); x++) {
            auto position = Vector2{
                .x = x,
                .y = y,
            };

            totalXmas += isXmas(lines, position);
        }
    }
    return totalXmas;
}

int part2(std::vector<std::string> lines) {
    int totalXmas = 0;
    for ( int y = 0; y < lines.size(); y++) {
        for (int x = 0; x < lines[0].length(); x++) {
            auto position = Vector2{
                .x = x,
                .y = y,
            };

            totalXmas += isCrossMas(lines, position);
        }
    }
    return totalXmas;
}

int main() {
    auto lines = linesFromFile("./input.txt");

    std::cout << "Part 1: " << part1(lines) << std::endl;
    std::cout << "Part 2: " << part2(lines) << std::endl;

    return 0;
}
