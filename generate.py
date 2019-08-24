#!/usr/bin/python3

import os
import sys


class InitFileGenerator:

    GENERATE_INIT_FILES = True

    INIT_FILE_EXTENSIONS = [
        '.gd',
        '.gdns'
    ]
    INIT_FILE_NAME = '__init__.gd'


    @staticmethod
    def generate_init_file(path, directories, files):
        if not InitFileGenerator.GENERATE_INIT_FILES:
            return

        # Filter files
        files = [file for file in files if file.endswith(tuple(InitFileGenerator.INIT_FILE_EXTENSIONS))]
        if not len(files):
            return

        # Fetch filenames
        file_names = [os.path.splitext(file)[0] for file in files]

        absolute_init_file_path = os.path.join(path, InitFileGenerator.INIT_FILE_NAME)

        # Remove old init file
        InitFileGenerator.remove_old_init_file(absolute_init_file_path)

        # Create init file content
        init_file_content = '\n'

        # Create init file directories content
        init_file_content_directories = ''
        for directory in directories:
            f_relative_init_file_path = os.path.join(directory, InitFileGenerator.INIT_FILE_NAME)
            f_absolute_init_file_path = os.path.join(path, f_relative_init_file_path)

            # If current folder already has class and folder
            # with same name, append D to a directory name
            if directory in file_names:
                directory += 'D'

            if os.path.isfile(f_absolute_init_file_path):
                init_file_content_directories \
                    += InitFileGenerator.generate_preload_statement(directory, f_relative_init_file_path)

        if len(directories):
            init_file_content += init_file_content_directories + '\n'

        # Create init file files content
        init_file_content_files = ''
        for file in files:
            file_name = os.path.splitext(file)[0]

            if file_name:
                init_file_content_files += InitFileGenerator.generate_preload_statement(file_name, file)

        # Create new init file
        InitFileGenerator.create_new_init_file(
            absolute_init_file_path,
            init_file_content + init_file_content_files
        )


    @staticmethod
    def generate_preload_statement(variable_name, path):
        return 'const {} = preload(\'{}\')\n'.format(variable_name, path)


    @staticmethod
    def remove_old_init_file(path):
        if os.path.isfile(path):
            try:
                os.remove(path)
            except e:
                print("Failed to remove file {}.\n{}".format(path, e))


    @staticmethod
    def create_new_init_file(path, content = ''):
        if os.path.isfile(path):
            InitFileGenerator.remove_old_init_file(path)
        else:
            try:
                open(path, 'w').write(content)
            except e:
                print("Failed to create file {}.\n{}".format(path, e))



class Parser:

    SOURCE_DIRECTORY = 'src'

    IGNORE_DIRECTORIES = []
    IGNORE_FILES = [
        InitFileGenerator.INIT_FILE_NAME
    ]


    @staticmethod
    def parse_directory(path, directory_name = ''):
        directories = []
        files = []

        if len(directory_name):
            path = os.path.join(path, directory_name)

        for (dirpath, dirnames, filenames) in os.walk(path):
            directories.extend(dirnames)
            files.extend(filenames)
            break

        # Jump into source directory if supplied with module directory
        if Parser.SOURCE_DIRECTORY in directories:
            Parser.parse_directory(path, Parser.SOURCE_DIRECTORY)
            return

        for directory in directories:
            if directory not in Parser.IGNORE_DIRECTORIES:
                Parser.parse_directory(path, directory)

        # Filter ignored files
        files = [file for file in files if file not in Parser.IGNORE_FILES]

        # Generate init files
        InitFileGenerator.generate_init_file(
            path,
            directories,
            files
        )


def main(args):
    args_len = len(args)
    if args_len > 1:
        Parser.parse_directory(os.path.abspath(args[args_len - 1]))


main(sys.argv)
