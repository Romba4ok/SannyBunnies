import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sannybunnies/services/user/profile_service.dart';

class AddChildPage extends StatefulWidget {
  final String parentUid;
  final Map<String, dynamic>? initialData;

  const AddChildPage({
    Key? key,
    required this.parentUid,
    this.initialData,
  }) : super(key: key);

  @override
  State<AddChildPage> createState() => _AddChildPageState();
}

class _AddChildPageState extends State<AddChildPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dateController;
  late TextEditingController _feature1Controller;
  late TextEditingController _feature2Controller;
  late TextEditingController _feature3Controller;

  String? _selectedGender;
  XFile? _pickedPhoto;
  bool _isSaving = false;

  bool get _isEdit => widget.initialData != null;

  final List<String> _genderOptions = ['Мужской', 'Женский'];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _nameController = TextEditingController(text: data?['name'] ?? '');
    _dateController = TextEditingController(text: data?['birthDate'] ?? '');
    _selectedGender = data?['gender'];

    final List<dynamic> features = data?['features'] as List<dynamic>? ?? [];
    _feature1Controller = TextEditingController(
      text: features.isNotEmpty ? features[0].toString() : '',
    );
    _feature2Controller = TextEditingController(
      text: features.length > 1 ? features[1].toString() : '',
    );
    _feature3Controller = TextEditingController(
      text: features.length > 2 ? features[2].toString() : '',
    );
  }

  Future<void> _pickChildPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (file == null) return;
    setState(() {
      _pickedPhoto = file;
    });
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    DateTime initialDate;
    if (_dateController.text.isNotEmpty) {
      try {
        final parts = _dateController.text.split('.');
        initialDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      } catch (_) {
        initialDate = now.subtract(const Duration(days: 365 * 4));
      }
    } else {
      initialDate = now.subtract(const Duration(days: 365 * 4));
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2008),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFA441DC),
            onPrimary: Colors.white,
            surface: Color(0xFF1B191B),
            onSurface: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFA441DC),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (date == null) return;
    _dateController.text =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    setState(() {});
  }

  Future<void> _saveChild() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isEdit && _pickedPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте фото ребёнка')),
      );
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите пол ребёнка')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final String childId = _isEdit
          ? widget.initialData!['id']
          : ProfileService.instance.generateChildId(widget.parentUid);

      Uint8List? photoBytes;
      if (_pickedPhoto != null) {
        photoBytes = await File(_pickedPhoto!.path).readAsBytes();
      }

      final Map<String, dynamic> childData = {
        'name': _nameController.text.trim(),
        'gender': _selectedGender,
        'birthDate': _dateController.text.trim(),
        'features': [
          _feature1Controller.text.trim(),
          _feature2Controller.text.trim(),
          _feature3Controller.text.trim(),
        ],
        'photoUrl': widget.initialData?['photoUrl'],
      };

      if (!_isEdit) {
        childData.addAll({
          'group_id': null,
          'mood': null,
          'inKindergarten': null,
          'healthText': null,
          'requestStatus': false,
        });
      }

      await ProfileService.instance.saveChild(
        widget.parentUid,
        childId,
        childData,
        photoBytes: photoBytes,
        isNew: !_isEdit,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _feature1Controller.dispose();
    _feature2Controller.dispose();
    _feature3Controller.dispose();
    super.dispose();
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF808080), Color(0xFF303030)],
        ),
      ),
      padding: const EdgeInsets.all(1),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          color: const Color(0xFF0F0D0D),
        ),
        child: TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: InputBorder.none,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Заполните поле';
            }
            return null;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final photoUrl = widget.initialData?['photoUrl'];

    return Scaffold(
      backgroundColor: const Color(0xFF131010),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  height: size.height * 0.20,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/loginPage/logo.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        _isEdit ? 'Редактирование ребенка' : 'Регистрация ребенка',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isEdit
                            ? 'Измените необходимые данные ребенка'
                            : 'Заполните все поля для регистрации',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildField(
                              controller: _nameController,
                              hint: 'ФИО ребенка',
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF808080), Color(0xFF303030)],
                                ),
                              ),
                              padding: const EdgeInsets.all(1),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(11),
                                  color: const Color(0xFF0F0D0D),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: DropdownButtonFormField<String>(
                                  value: _selectedGender,
                                  hint: const Text(
                                    'Выберите пол',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                  dropdownColor: const Color(0xFF0F0D0D),
                                  iconEnabledColor: Colors.white54,
                                  style: const TextStyle(color: Colors.white),
                                  items: _genderOptions
                                      .map(
                                        (value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(value),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedGender = value);
                                    }
                                  },
                                  validator: (value) =>
                                      value == null ? 'Выберите пол' : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _pickBirthDate,
                              child: AbsorbPointer(
                                child: _buildField(
                                  controller: _dateController,
                                  hint: 'Дата рождения',
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Особенности / Отклонения / Болезни (3 поля)',
                              style:
                                  TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              controller: _feature1Controller,
                              hint: 'Особенность 1',
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              controller: _feature2Controller,
                              hint: 'Особенность 2',
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              controller: _feature3Controller,
                              hint: 'Особенность 3',
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Фото ребенка (обязательно)',
                              style:
                                  TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _pickChildPhoto,
                              child: Container(
                                width: double.infinity,
                                height: 180,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFA441DC),
                                    width: 1.5,
                                  ),
                                  color: const Color(0xFF1B191B),
                                ),
                                child: _pickedPhoto != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.file(
                                          File(_pickedPhoto!.path),
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : (photoUrl != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            child: FutureBuilder<List<int>?>(
                                              future: ProfileService.instance.getCachedPhotoBytes(photoUrl),
                                              builder: (context, snap) {
                                                if (snap.connectionState == ConnectionState.done && snap.data != null) {
                                                  return Image.memory(
                                                    Uint8List.fromList(snap.data!),
                                                    fit: BoxFit.cover,
                                                  );
                                                }
                                                if (snap.connectionState == ConnectionState.waiting) {
                                                  return Container(
                                                    color: Colors.black.withOpacity(0.1),
                                                    child: const Center(
                                                      child: CircularProgressIndicator(color: Color(0xFFA441DC)),
                                                    ),
                                                  );
                                                }
                                                return Image.network(photoUrl, fit: BoxFit.cover);
                                              },
                                            ),
                                          )
                                        : const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_a_photo,
                                                color: Color(0xFFA441DC),
                                                size: 40,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Нажмите, чтобы выбрать фото',
                                                style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          )),
                              ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveChild,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFA441DC),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _isEdit
                                            ? 'Сохранить изменения'
                                            : 'Зарегистрировать',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 15,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}


